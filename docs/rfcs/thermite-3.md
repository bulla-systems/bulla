# Thermite 3

The surface, in full, with each construct marked by when it lands and where its
design lives. Read top to bottom it is a specification; read the status column it
is a roadmap.

**Status: FILED** as [Thermite RFC-7 / PR #129](https://github.com/dollspace-gay/Thermite/pull/129),
stacked on the anchor. The upstream copy is adapted — links to sibling documents
here become forward references, since those documents are not upstream — and it
asks for a direction check rather than for any capability.

The sequencing rule below is unaffected: the *horizon* is filed, and steps 4
through 9 stay unfiled until the anchor lands.

## The name is borrowed, not invented

Upstream already numbers generations:
[#2](https://github.com/dollspace-gay/Thermite/issues/2), "Thermite 2 — a
dependent-type tier, a stratified cage, and new ladder boundaries." There is a
convention for a generational proposal and this follows it.

**Thermite 3 is a surface generation, not a semantics one.** Thermite 2 changed
what the language can prove. This changes what it reads like, and then adds
capability on top of the settled surface. That distinction is what makes the
sequence work: the expensive-to-review part and the cheap-to-review part are
separable, and the cheap one goes first.

## Why, and what Bulla has to do with it

The motivation is Thermite's own stated purpose. It is designed to be written
principally by agents, and a surface built for that has requirements a
human-authored one does not: a keyword's cost is not the tokens it spends but the
prior it activates, and a clause read wrongly yields a vacuous proof rather than
an error. `fx`, `dec` and `inv` are not merely terse — they point at effects,
declarations and inverses. That is a gap between what the language is for and
what it currently reads like, and closing it is the whole of the anchor.

**Bulla's role is discovery, not entitlement.** It is a workload chosen to press
on the language hard enough to find where the surface and the capability run out:
a kernel needs structural predicates, shared state, ownership, interference and
protocols, and it needs them in a form an agent can write correctly. Every gap
in [docs/language-gaps.md](../language-gaps.md) was found by attempting something
rather than by reading the reference, and several contradicted the documentation
in both directions.

What that buys is evidence, not standing. Bulla has no verified subsystem, and a
proposal here earns its way on the design and the reproduction attached to it.

## The throughline

One principle, and every document here inherits it:

> Thermite is written principally by language models, so **semantic overlap with
> pretraining is worth more than token economy** — and abbreviations do not merely
> fail to help, they misdirect. In a language where a misread clause yields a
> vacuous proof rather than a compile error, that is a safety property.

Three rules follow, and between them they decided every name below:

1. **Full words**, except where a symbol *is* the concept.
2. **Every clause is a third-person-singular verb whose subject is the item**, so
   a clause reads as a sentence with the subject elided.
3. **A thing that is not a claim about behaviour is not a clause.** The effect row
   belongs to the arrow; modifiers are adjectives on an item.

---

# The language

Status marks what a construct costs to adopt:

| mark | meaning |
|---|---|
| **anchor** | in [the syntax-only change](full-words-anchor.md). No new expressive power |
| **rung N** | a capability, at that rung of [the ladder](../the-ladder.md) |
| **research** | reachable surface, open discharge |

## 1. Functions

```thermite
fn allocate(pages: u64) -> Result<Grant, u64>
  ! write(heap), cost(12 * pages + 40)
  requires {
    pages > 0;
    pages <= 1024;
  }
  ensures match result {
    Ok(g)  => g.len == pages * 4096 && plan_ok(current_plan()),
    Err(e) => true,
  } by unfold(plan_ok)
```

The signature, then the effect row, then the clauses. Ordering is mandatory:

```
1. the effect row      — it is part of the type
2. bare clauses        — requires, ensures, survives
3. blocks              — interleaves { }
4. measures            — last, as Verus places `decreases`
```

Nothing semantic has to be known to check that order. **anchor**

## 2. Clauses

| clause | on | says | status |
|---|---|---|---|
| `requires P` | fn | holds at entry | **anchor** (from `req`) |
| `ensures P` | fn | holds at normal exit | **anchor** (from `ens`) |
| `keeps P` | struct, enum, loop | always true of this | **anchor** (from `inv`) |
| `measures E` | spec fn, loop, recursive fn | a well-founded quantity that decreases | **anchor** (from `dec`) |
| `ensures P` | spec fn | the interface of a sealed predicate | [rung 1–2](structured-spec-surface.md) |
| `survives P` | fn | holds if execution stops mid-step | [crash clause](crash-clause.md) |
| `asks R` / `promises G` | fn, inside `interleaves` | what others may do to me / what I do to them | [rung 6](interference-clauses.md) |

A clause body may be a bare expression or a **block of conjuncts**, which is what
makes a proof hint attach per obligation rather than per clause:

```thermite
requires {
  cpu < 64;
  (s.expected >> cpu) & 1 == 1;
}
```

**anchor.** The trivial precondition is `requires nothing`. A trivial
postcondition is refused by the assurance gate — `ens true` is `EnsIsTrivial`
§7.1(a) today — so `ensures nothing` parses, says what it means, and does not
certify.

## 3. The effect row

```thermite
  ! write(heap), cost(12 * pages + 40)
  ! pure
  ! blocks
```

Type-level, not a predicate: `() ! pure` and `() ! write(shootdown)` are
different types. The line between the row and the clauses:

> **An effect propagates up the call graph by construction. A clause is proved at
> the item.**

Two families, and the shape is the discriminator:

| family | shape | atoms | composition | status |
|---|---|---|---|---|
| state | names a region | `read(r)` `write(r)` `owns(r)` `forgets(r)` | union | [rung 3](verified-effect-rows.md) for the check |
| control | describes the arrow | `panic` `diverge` `blocks` `cost(E)` `random` | or; sum for `cost` | mixed |

**The rule for which name a row carries:** a `shared` thing is named, a
`resource` thing is not, because ownership already gives exclusivity. So global
state needs `write(shootdown)` and a channel endpoint needs only `blocks`.

An effect is an algebraic theory, and each label owes a theory, a composition
law, and a **commutation fact** — the third being what makes the conflict table a
theorem rather than an axiom. [The effect algebra](effect-algebra.md) carries the
basis and the admissibility criterion.

User-declared effects, as combinations of a fixed basis:

```thermite
effect platform(d) = state(d)
effect journal(d)  = state(d) + exception
```

[effect algebra](effect-algebra.md#user-declared-effects)

## 4. Specification vocabulary

```thermite
opaque spec fn plan_ok(p: Plan) -> bool
  ensures   !result || p.count > 0     // the interface, visible while sealed
  measures  p.count
{ ...expensive, quantifies over p.regions... }
```

`opaque` seals the body; consumers reason from `ensures`. Establishing a sealed
predicate costs an unfold, declared where a reader sees it:

```thermite
  ensures match result { Ok(p) => plan_ok(p), Err(e) => true }
          by unfold(plan_ok)
```

**The asymmetry is the design**: assuming an opaque predicate is free,
establishing one costs an unfold. `by` is per-obligation and extensible — other
hints join without new syntax. [rung 1–2](structured-spec-surface.md)

## 5. Data

```thermite
struct Shoot { epoch: u64, acked: u64, expected: u64 }
  keeps acked & !expected == 0

enum Walk { Ready { addr: u64 }, Pending { level: u32, index: u64 } }
```

**anchor** for `keeps`. Structural predicates over recursive data and quantified
predicates over collections are [rungs 1 and 2](structured-spec-surface.md), and
are a defect report rather than a feature request — the language already intends
to support them.

## 6. Resources

```thermite
resource struct Grant { base: u64, len: u64, generation: u64 }
  keeps base + len <= MAX_PHYS
```

A `resource` binding is consumed on every path **that returns** — scoped exactly
as `ensures` is. Contagion is declared and checked: a struct or enum reachable to
a resource is itself a resource. Abandonment is an operation rather than a hole:

```thermite
fn teardown(g: Grant) -> ()
  ! forgets(heap)
  requires  nothing
  ensures   nothing
{ forget(g) }
```

[rung 5](resource-types.md) — the rung where a verified Unix kernel becomes
conceivable rather than a verified box around an unverified one.

## 7. Shared state

```thermite
shared heap:       Heap
shared scheduler:  SchedState
shared interrupts: MaskState
```

`shared` rather than `region`: the jargon names the mechanism, the word names the
safety-relevant property. Declaring it is what makes the row checkable, and the
conflict rule follows. [rung 3](verified-effect-rows.md)

## 8. Locks

```thermite
lock sched_lock guards SchedState;
lock frame_lock guards FrameTable after sched_lock;

fn enqueue(t: TaskId) -> ()
  ! owns(sched_lock), write(scheduler)
  requires  t < MAX_TASKS
  ensures   nothing
{ holding sched_lock { … } }
```

The row declares **which** lock; the block declares **where**. Neither is
inferred, so an over-declared lock is an error rather than invisible. A function
holds at most one lock unless the locks are ordered with `after`.
[rung 4](shared-state-invariants.md)

## 9. Interference

```thermite
fn ack(s: &mut Shoot, cpu: u64) -> ()
  ! write(shootdown)
  requires  cpu < 64
  ensures   (final(s).acked >> cpu) & 1 == 1
  interleaves {
    asks      final(s).acked | s.acked == final(s).acked;
    promises  final(s).acked == s.acked | (1 << cpu);
  }

interleaves shootdown { ack, complete }
```

For shared state read without a lock, where monotonicity is what makes the read
mean something. `asks`/`promises` outside the block is a parse error, because
`requires`/`ensures` is also ask-and-promise and only the block names the party.
[rung 6](interference-clauses.md)

## 10. Interrupts

```thermite
handlers { ipi_shootdown at 2, timer_isr at 1 }
```

Not an effect. A handler is the environment, masking is `owns(interrupts)`, and
the declaration carries a **preemption order** so the pairwise obligation is
generated only in the direction that can happen. Handler atomicity is a stated
platform assumption. [effect algebra](effect-algebra.md#irq-is-not-a-primitive)

## 11. Protocols

```thermite
protocol PageRequest {
  User     { op: u32, count: u64 },
  Provider { status: u32, base: u64 },
  end
}

fn pager(c: PageRequest::Provider) -> () ! blocks
fn app(c: PageRequest::User)       -> () ! blocks
```

A sequence of turns, each labelled with whose turn it is. Roles are names, so a
protocol names its own; an endpoint is a path to a role, and it is a `resource`.
Termination is load-bearing: running the protocol to completion is what consumes
the endpoint. Conditional repetition is a branch, `repeat | end`, and a branch
costs a discriminant on the wire. [rung 7](protocol-types.md)

## 12. Loops

```thermite
while i > 0
  keeps     i <= n
  measures  i
{
  i = i - 1;
}
```

Clauses sit between the head and the body, as a function's sit between its
signature and its body. **anchor** for the renames.

## 13. Durability

```thermite
fn commit(j: &mut Journal, b: Block) -> ()
  ! write(disk), panic
  requires  j.open
  ensures   final(j).committed == j.committed + 1
  survives {
    final(j).recoverable;
    final(j).committed == j.committed
      || final(j).committed == j.committed + 1;
  }
```

`survives` is the crash-time analogue of `ensures`. The logic is settled — Crash
Hoare Logic, FSCQ — and the work is the **crash model**, which is a per-device
trusted assumption. [crash clause](crash-clause.md)

## 14. Where this is going

Reachable surface, open discharge. On [the ladder](../the-ladder.md#the-rungs)
rather than in this sequence.

```thermite
fn hash(seed: u64) -> u64
  ! random(Uniform)                    // rung 11 — distributional effects
  requires  nothing
  ensures   result is Uniform

fn dispatch(t: TaskId) -> ()
  ! write(scheduler), cost(180)        // rung 9 — cost discharged, not declared
  requires  t < MAX_TASKS
  ensures   nothing
```

`cost(E)` is already in the row and already composes; what is open is the
analysis that discharges it. `random` is already an atom and is designed to
accept a parameter later, so gaining `random(D)` is not a breaking change — and
that is what a cryptographic argument needs: stipulate a distribution on an
input, certify the output's.

Also out: noninterference, which is a hyperproperty about *sets* of executions;
an algebra for composing certificates; user-supplied effect equations; and effect
handlers in the Koka sense.

---

# Rollout

## The anchor

The first proposal changes **no expressive power whatsoever**. Written out as
[full words](full-words-anchor.md), which is the document to hand someone.

Five renames — `req` `ens` `inv` `dec` `fx` — plus the row moving to the front,
the fixed clause order, conjunct blocks, and `requires nothing`. 547 clause
sites across 67 files, a deterministic rewrite, certificates unaffected.

**One deliberate exception.** `alloc` and `rand` are abbreviations that rule 1
would rename. The anchor leaves them, because
[verified effect rows](verified-effect-rows.md) turns them into `write(heap)` and
`write(entropy)` anyway and renaming a token twice is churn.

## The sequence

```
1. defects                    FILED — #124, #125, #126
2. the RFC process            FILED — Thermite PR #127
3. the anchor                 FILED — Thermite PR #128
4. the effect algebra         what a row is; underpins 5
5. verified effect rows       rung 3, the multiplier
6. shared-state invariants    rung 4
7. resource types             rung 5, the honest goal
8. interference clauses       rung 6
9. protocol types             rung 7
```

Defects go first because they are the dependency, not the diplomacy: #124 is
rung 1, and no structural predicate over an ADT works until it is fixed. Filed
2026-08-05.

The RFC process goes second because Thermite's only RFC namespace is its issue
tracker, which models reports and cannot version a proposal.

## The dependency tree

```
                    full-words-anchor
                            │
                    effect-algebra
                            │
                    verified-effect-rows ──────┐
                            │                  │
                    shared-state-invariants    │
                            │                  │
                    interference-clauses ──────┤
                                               │
resource-types ────────────────────────────────┴──→ protocol-types

crash-clause          independent; unscheduled
structured-spec-surface  independent; defects, files first
```

Protocols need resources, because an endpoint that can be dropped abandons its
peer mid-session. Interference needs both the row and the lock discipline,
because its claim is that it is the cheaper option where those two are too
strong. The spec surface is independent of all of it and files first, because it
is four defects with reproductions rather than a proposal.

## Readiness

| document | state |
|---|---|
| [structured spec surface](structured-spec-surface.md) | **FILED** — [#124](https://github.com/dollspace-gay/Thermite/issues/124), [#125](https://github.com/dollspace-gay/Thermite/issues/125), [#126](https://github.com/dollspace-gay/Thermite/issues/126) |
| [full words](full-words-anchor.md) | **FILED** — [PR #128](https://github.com/dollspace-gay/Thermite/pull/128), on top of #127 |
| [surface conventions](surface-conventions.md) | **ready** — the design record behind the anchor |
| [the effect algebra](effect-algebra.md) | **ready** |
| [verified effect rows](verified-effect-rows.md) | **ready** — migration, kernel break and cert impact all stated |
| [shared-state invariants](shared-state-invariants.md) | **ready** — lock scope, the one-lock default, and the masking rule settled |
| [resource types](resource-types.md) | **ready** — contagion, `forget`, and `panic` settled |
| [interference clauses](interference-clauses.md) | **ready** — the lowering hypothesis is discharged, with the stability gap recorded |
| [protocol types](protocol-types.md) | ready as a document; depends on resource types landing |
| [the crash clause](crash-clause.md) | **ready** — the crash model is named as the gate, with a first model stated |
| **this document** | **FILED** — [PR #129](https://github.com/dollspace-gay/Thermite/pull/129), the horizon, on top of #128 |

## The cost of each step

Read in order, the work is small and gets larger:

1. Three defect reports with reproductions and located fixes. **Filed** —
   [#124](https://github.com/dollspace-gay/Thermite/issues/124),
   [#125](https://github.com/dollspace-gay/Thermite/issues/125),
   [#126](https://github.com/dollspace-gay/Thermite/issues/126).
2. A process proposal that migrates the four existing RFCs out of issues and
   adds a front-matter field feeding the REQ registry. **Filed** as
   [PR #127](https://github.com/dollspace-gay/Thermite/pull/127), with its gate
   script, its own requirements, and the migration done.
3. A rename with a migration tool and a corpus that still certifies. **Filed**
   as [PR #128](https://github.com/dollspace-gay/Thermite/pull/128), with the
   spike, the counts and the certification table attached.

Nothing after step 3 is proposed until those land, because a surface nobody
adopted is not a foundation for six proposals. Filing this document as RFC-7 is
not an exception to that: it proposes no capability and introduces no
requirement, and it exists so the anchor reads as one step of a stated plan
rather than as five keyword renames. Steps 4 through 9 stay unfiled.

## The whole surface in one file

[`docs/examples/thermite3-tour.th`](../examples/thermite3-tour.th) writes every
construct above out as one coherent paging subsystem. It does not certify, and
says so in its header: the syntax is proposed, not shipped.
[`tooling/editor/`](../../tooling/editor/) has syntax highlighting for it.
