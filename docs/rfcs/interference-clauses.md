# Interference clauses

**Rung 6.** Kind: two new clauses, shaped like `requires` and `ensures`.

## What it adds over the effect-rows RFC and the shared-state-invariants RFC

| | covered by |
|---|---|
| disjoint state | the effect-rows RFC |
| shared, serialised | the shared-state-invariants RFC |
| **shared, lock-free, monotone** | **this** |
| shared, lock-free, arbitrary | needs full CSL/Iris; out of scope |

The shared-state-invariants RFC's vocabulary is *"nobody touches this while I
hold it"*. This RFC's is *"others may touch it, in these ways"* — a weaker
guarantee than mutual exclusion, which is what lets a read proceed without a
lock.

## Proposal

```thermite
fn ack(s: &mut Shoot, cpu: u64) -> ()
  ! write(shootdown)
  requires {
    cpu < 64;
    (s.expected >> cpu) & 1 == 1;
  }
  ensures  (final(s).acked >> cpu) & 1 == 1
  interleaves {
    asks {
      final(s).epoch == s.epoch;
      final(s).acked | s.acked == final(s).acked;          // what may come at me
    }
    promises {
      final(s).epoch == s.epoch;
      final(s).acked == s.acked | (1 << cpu);              // what I put out
    }
  }
```

`requires`/`ensures` are **predicates** on one state — boundaries.
`asks`/`promises` are **relations** between two states — duration. The verb says
who acts: this function asks something of its peers and promises something to
them.

An earlier draft used `<~` and `~>` for the two directions. Those were glyphs
invented to dodge a collision that abbreviation had caused, and
[the surface conventions](surface-conventions.md) retired them: symbol space is
small and adversarial, so a new concept gets a word.

The `interleaves` block marks the function concurrent, so no separate effect atom
is needed. `asks` or `promises` outside the block is a parse error rather than a
convention, because `requires`/`ensures` is also ask-and-promise — to the caller
rather than the environment — and only the block names the party.

## Composition

At the site declared by the effect-rows RFC:

```thermite
interleaves shootdown { ack, complete }
```

discharge, pairwise:

```
promises(ack)      ⟹ asks(complete)
promises(complete) ⟹ asks(ack)
```

For the example above both reduce to propositional facts about bitwise-or. Note
it stays pairwise as participants are added, which is what makes rely-guarantee
compositional at all.

## Two obligations that should be checked, not assumed

**The relations must be preorders** — reflexive (doing nothing is permitted) and
transitive (many steps compose into one). Malformed contracts otherwise produce
vacuous proofs.

**`ensures` must be stable under `asks`**:

```
Q(s) ∧ R(s, s′) ⟹ Q(s′)
```

This is where newcomers to rely-guarantee get burned. If you establish
`acked == expected` while others can still set bits, the postcondition was never
true in any useful sense. Making stability explicit is worth more than it costs.

## How these clauses are scored

Unexamined upstream, and it does not fall out of the existing machinery. Forge
scores a contract by mutating the **body** and asking whether the contract kills
the mutant — a contract that fails to distinguish a deliberately wrong body is
reported `WeakContract` (`.design/forge/mutation-scoring.md` §7). The two clauses
here sit on opposite sides of that.

**`promises` scores like `ensures`.** It is a claim about this function's own
steps, so a body mutant that violates the guarantee is killed by the guarantee,
using the machinery that already exists. One dependency: the observable has to
include the effect trace on shared state rather than only the return value, which
is `equivalent-mutants.md` **OQ-2** — "an effectful body's observable result would
also include its effect trace" — currently out of scope, since v0.1 scores
`fx pure` bodies. So `promises` is scoreable in principle and not scoreable yet.

**`asks` has no body mutant at all.** It is a claim about the *environment*. No
mutation of this function's body can violate it, so mutation scoring is silent on
it — and silence here reads as a pass. Two different hazards need two different
probes:

| hazard | probe |
|---|---|
| the rely is unnecessary — it assumes something the proof never uses | weaken it: does the obligation still discharge with `asks nothing`? If it does, the clause is doing no work. This is a strengthening probe, not a mutation |
| the rely is unjustified — it assumes more than any peer guarantees | discharge it at the composition site: every peer's `promises` must imply it. Not a per-item check at all |

The second is the dangerous one, and it has no home today. Until a composition
site exists, an `asks` is a free assumption that makes this function's proof
easier and is checked against nothing — the same shape as
`! write(a_resource_that_does_not_exist)` certifying at L3 before the effect-rows
RFC makes the row checkable.

**So an undischarged `asks` must not be reported at full assurance.** In the
vocabulary of [the assurance model](../assurance-model.md), a function whose rely
has never been discharged against a peer carries a weaker boundary coordinate
than one whose has, and the per-clause tuple should say so rather than averaging
it away. A rely-guarantee proof with no peers is a conditional proof, and the
condition is the part a reader needs to see.

## Why the kernel wants it

Every case is monotone, lock-free, and on a path where a lock hurts:

- TLB shootdown acknowledgement masks
- capability generation counters read without locking
- allocator watermarks that only rise
- per-CPU phase flags that only advance

## Metatheory

Rely-guarantee (Jones, 1983), refined through RGSep (Vafeiadis and Parkinson,
2007) and generalised by Iris. Settled and mechanised. The pinned Verus ships
`atomic_ghost.rs` and `state_machines_macros`.

**Lowering hypothesis, flagged as unverified:** that `asks`/`promises` factor
onto the tokenized-state-machine machinery, giving a Thermite-idiomatic surface
over Verus's existing soundness. Someone should check that before proposing it.

## Sequencing

This is the right *third* thing. Everything it enables is an optimisation of
something the shared-state-invariants RFC already expresses correctly but slowly.
Build the effect-rows RFC and the shared-state-invariants RFC, find out
empirically which paths hurt, then write these contracts for those call sites —
where you will know what they need to say.

## Dependency

`final()` currently exists only for `&mut` parameters. Two-state relations over a
shared `&` parameter need it there too — a small extension to existing vocabulary
rather than a new concept, but a change, and it should be named.
