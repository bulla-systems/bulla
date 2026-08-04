# RFC-005 — Interference clauses: `<~` and `~>`

**Rung 6.** Kind: two new clauses, shaped like `req` and `ens`.

## What it adds over RFC-002 and RFC-003

| | covered by |
|---|---|
| disjoint state | RFC-002 |
| shared, serialised | RFC-003 |
| **shared, lock-free, monotone** | **this** |
| shared, lock-free, arbitrary | needs full CSL/Iris; out of scope |

RFC-003's vocabulary is *"nobody touches this while I hold it"*. This RFC's is
*"others may touch it, in these ways"* — a **weaker guarantee than mutual
exclusion**, which is what lets a read proceed without a lock.

## Proposal

```thermite
fn ack(s: &mut Shoot, cpu: u64) -> ()
  req  cpu < 64 && (s.expected >> cpu) & 1 == 1
  <~   final(s).epoch == s.epoch
       && final(s).acked | s.acked == final(s).acked     // what may come at me
  ~>   final(s).epoch == s.epoch
       && final(s).acked == s.acked | (1 << cpu)         // what I put out
  ens  (final(s).acked >> cpu) & 1 == 1
  fx   write(shootdown)
```

`req`/`ens` are **predicates** on one state — boundaries. `<~`/`~>` are
**relations** between two states — duration. Direction says who acts: `<~`
arrives at me, `~>` leaves me.

The arrows rhyme with [RFC-006](006-protocol-types.md) without colliding:
straight `->` `<-` for discrete **messages**, squiggly `~>` `<~` for ambient
**state drift**.

Presence of the arrows marks a function as concurrent; no separate atom is
needed, consistent with the language's treatment of clause absence as meaningful.

## Composition

At the site declared by RFC-002:

```thermite
concurrent shootdown { ack, complete }
```

discharge, pairwise:

```
~>(ack)      ⟹ <~(complete)
~>(complete) ⟹ <~(ack)
```

For the example above both reduce to propositional facts about bitwise-or. Note
it stays pairwise as participants are added, which is what makes rely-guarantee
compositional at all.

## Two obligations that should be checked, not assumed

**The relations must be preorders** — reflexive (doing nothing is permitted) and
transitive (many steps compose into one). Malformed contracts otherwise produce
vacuous proofs.

**`ens` must be stable under `<~`**:

```
Q(s) ∧ R(s, s′) ⟹ Q(s′)
```

This is where newcomers to rely-guarantee get burned. If you establish
`acked == expected` while others can still set bits, the postcondition was never
true in any useful sense. Making stability explicit is worth more than it costs.

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

**Lowering hypothesis, flagged as unverified:** that `<~`/`~>` factor onto the
tokenized-state-machine machinery, giving a Thermite-idiomatic surface over
Verus's existing soundness. Someone should check that before proposing it.

## Sequencing

This is the right *third* thing. Everything it enables is an optimisation of
something RFC-003 already expresses correctly but slowly. Build RFC-002 and
RFC-003, find out empirically which paths hurt, then write these contracts for
those call sites — where you will know exactly what they need to say.

## Dependency

`final()` currently exists only for `&mut` parameters. Two-state relations over a
shared `&` parameter need it there too — a small extension to existing
vocabulary rather than a new concept, but a change, and it should be named.
