# RFC-002 — Verified effect rows, and regions

**Rung 3.** Kind: extension to an existing mandatory clause.

## The framing

The proposal is not "add concurrency to Thermite". It is:

> **Make effect rows verified rather than asserted.**

Race-freedom falls out as a consequence, and with it multi-core.

## The problem it starts from

Today `fx write(db)` is an **unchecked claim**. Nothing declares `db`; nothing
verifies the function touches only it. The effect row is documentation that
happens to be syntax.

That is a weakness independent of concurrency. A function may quietly touch
authority it never declared, and the row will not notice.

## Proposal

Declare resources, so the row can be checked against them:

```thermite
region sched:     SchedState;
region shootdown: Shoot;
region clock:     TimeState;
```

A region names a piece of shared state and its type. For a kernel this fits
naturally: shared state is static.

Effect atoms stay exactly as they are — `read(r)` and `write(r)`, the existing
`verb(resource)` pattern generalised to a new resource kind:

```thermite
fn advance() -> u64
  req  true
  ens  result < MAX_SLOTS
  fx   write(sched), read(clock)
```

The checker now verifies the row is honest, rather than trusting it.

## The concurrency consequence

Given honest rows, concurrent composition gets a conflict rule:

| | |
|---|---|
| `write(r)` ∥ `write(r)` | reject |
| `write(r)` ∥ `read(r)` | reject |
| `read(r)` ∥ `read(r)` | accept |

That is ordinary reader-writer exclusion, and it is exactly the condition for
data-race-freedom. By the DRF-SC theorem (Adve & Hill, 1990), a data-race-free
program cannot distinguish its execution from a sequentially consistent one.

**So every sequential proof already written stays valid, unchanged, on multiple
CPUs.** That is the whole return on this RFC.

Exclusivity is a property of the *composition rule*, not of the atom. `write(log)`
means the same thing it means today; the rule only fires where two functions are
composed concurrently. Applied uniformly it also catches two threads writing one
file, which is correct and currently unnoticed.

## Where the check happens

Concurrency in a kernel is not spawned dynamically — CPUs run handlers — so the
composition site can be declarative:

```thermite
concurrent shootdown_protocol { ack, complete }
```

## What this does not do

**It does not prevent deadlock.** Deadlock is about lock *ordering*, not
aliasing. Two functions each acquiring two regions in opposite orders both pass.
That needs a region partial order, and it is a real gap in this proposal.

**It does not help with lock-free sharing.** That is [RFC-005](005-interference-clauses.md).

**Interrupts are concurrency too**, and this is the kernel-specific case with no
userspace analogue. A handler preempts normal context on the *same* CPU, so
`write(sched)` in a handler races `write(sched)` in normal context even
single-threaded. The row needs to distinguish:

```thermite
fn timer_isr() -> ()
  req  true
  ens  true
  fx   irq, write(sched)
```

with `irq` functions conflicting with non-`irq` functions over the same region
unless the latter masks interrupts — itself an effect, `fx masked`.

## Open question to settle before implementation

**Granularity.** One region per subsystem serialises things that need not be.
Sub-regions (`region sched.runqueue: ...`) would help, but the conflict rule then
needs a containment order: `write(sched)` must conflict with
`read(sched.runqueue)`.

Tractable — it is a tree, and conflict is ancestry — but it is the difference
between a weekend and a fortnight, and retrofitting it is worse than deciding it.

## Metatheory

None new. DRF-SC is from 1990. The conflict check is syntactic: no solver, no
proof obligations. This is the only proposal in the set with that property, which
is why it is the best value per unit of work.
