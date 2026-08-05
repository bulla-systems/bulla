# Invariant-guarded shared state

**Rung 4.** Kind: extension reusing the struct invariant.

## Summary

[Verified effect rows](verified-effect-rows.md) permits only disjoint concurrent
access. This permits *shared* access, serialised, with the invariant holding at
every boundary.

The observation that makes it small: **a resource invariant is a struct
invariant.** `keeps` already exists and already means "always true of this type".
The only new thing is a scope in which it may be temporarily false.

## Proposal

```thermite
struct Counter { n: u64 }
  keeps n <= MAX

lock counters guards Counter;

fn bump(c: &mut Counter) -> ()
  ! owns(counters)
  requires  c.n < MAX
  ensures   final(c).n == c.n + 1
{ holding counters { c.n = c.n + 1; } }
```

`lock NAME guards TYPE;` is a new item form. It keeps the locking concern out of
the type declaration — the struct stays a plain struct with a plain invariant.

`owns(r)` joins `read(r)` and `write(r)` as a third mode: exclusive, established
dynamically.

## The scope of a lock

The rule that the invariant may be broken inside the critical section is only
meaningful once the critical section has edges. Two constructs give them, and
they carry different facts.

> **The row declares which locks a function takes. A block declares where.**

```thermite
fn bump(c: &mut Counter) -> ()
  ! owns(counters)
  requires  c.n < MAX
  ensures   final(c).n == c.n + 1
{
  … work outside the section …
  holding counters { c.n = c.n + 1; }
  … more work outside …
}
```

`owns(r)` in the row is what a caller sees and what the conflict rule composes.
`holding r { … }` is where the lock is actually held. Neither is optional, and
neither is inferred from the other.

### The three rules

1. **`owns(r)` requires a `holding r` block**, always. There is no whole-body
   default. Scoping the whole body is written `holding r { … }` around it.
2. **A `holding r` block requires `owns(r)` in the row.** Otherwise it is a parse
   error, by the same mechanism that puts `asks` inside `interleaves`: the row
   must be honest, and a caller cannot see a body.
3. **The row is an upper bound.** A `holding` block under an `if` is fine — the
   row says the lock may be taken, not that it is.

Rules 1 and 2 are one rule in two directions: the row and the body must agree
about every lock.

**Why no default.** An implicit whole-body scope makes an over-declared lock
invisible — `owns(r)` with no block is indistinguishable from "I meant the whole
body", so a lock that is declared and never taken reads as correct. That is a
declared-but-not-performed effect, which is what
[verified effect rows](verified-effect-rows.md) exists to stop, appearing one
level down:

```
error: `bump` declares `owns(sched_lock)` and no `holding` block takes it
```

It also makes acquisition order always available. Two locks in one function
produce two nested blocks, so the order is structural rather than unstated:

```thermite
holding src {
  holding dst { … }        // src before dst
}
```

### The obligation

For a `lock r guards T`, the guarded type's invariant is **assumed on entry to a
`holding r` block and must be proved on exit**, and is not assumed between. That
is the standard concurrent-separation-logic reading: you need to break the
invariant to do the update.

It needs no new clause syntax. The obligation derives from the
`lock … guards …` declaration rather than from anything written at the block, and
loops already show the language annotating a block, so this is not a new
syntactic category either. Thermite has no `assert` and no proof blocks
(verified: zero occurrences), and this needs neither.

### Why a block rather than a function

An earlier draft made the function body the critical section, on the grounds that
it reduces to clauses that already exist. Three things are wrong with that.

**It hides an over-declared lock.** Covered above, and it is the decisive one.

**Factoring is expensive here.** Narrowing a section by extracting a function
costs a full contract — `requires`, `ensures` and the row are all mandatory — so
scoping-only functions carry real signature noise. What is cheap in Rust is not
cheap in Thermite.

**Function scope cannot express the ordering this document's own open question
asks for.** `! owns(a), owns(b)` does not say which is taken first, so a deadlock
check has nothing to work with. Nested blocks state it structurally.

Because a block is lexical, the extent stays a syntactic property: reentrancy is
containment — no call lexically inside a `holding r` block may reach a function
whose row carries `owns(r)` — rather than a dataflow question. That would only
become flow-sensitive with separate acquire and release statements, which this
does not propose.

## The conflict rule gains three rows

The effect-rows RFC's table covers `read` and `write`. `owns` needs its own, and
the omission matters, because the interesting rows are the ones that reject:

| | |
|---|---|
| `owns(r)` ∥ `owns(r)` | **accept** — the lock serialises them, which is the point |
| `owns(r)` ∥ `write(r)` | **reject** — the writer bypasses the lock |
| `owns(r)` ∥ `read(r)` | **reject** — the reader observes a broken invariant |

So a guarded region may be touched only under its lock. Without those two
rejections, `lock r guards T` would be advisory: nothing would stop a second
function from writing `r` directly while the first holds it, and the invariant
that the lock exists to maintain would be maintained by convention.

This is also what makes `owns` different from "exclusion is achieved at runtime
so it conflicts with nothing statically". Runtime exclusion holds *between
holders of the lock*. It says nothing about a function that never takes it, and
that function is the one the static rule has to stop.

## Metatheory

Concurrent separation logic (O'Hearn and Brookes, 2004). Mechanised repeatedly,
and the pinned Verus ships `vstd/invariant.rs` and `vstd/rwlock.rs`, so the
substrate is present.

## Open questions

- **Reentrancy.** Does holding `owns(r)` permit calling something that also wants
  `owns(r)`? The answer is no, and because a `holding` block is lexical this is
  checkable by containment rather than by dataflow: no call inside a `holding r`
  block may reach a function whose row carries `owns(r)`.
- **Ordering.** `owns(a), owns(b)` in one function and `owns(b), owns(a)` in
  another deadlocks, and today both typecheck. Requiring blocks makes the order
  *stated*; it does not yet make it *checked*. Checking it needs a region partial
  order,
  which the effect-rows RFC also wants, and one order would close both at once.
  What this document contributes is that the order is now written down somewhere
  a checker could read.
