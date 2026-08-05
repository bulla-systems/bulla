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

`owns(r)` in the row is what a caller sees and what the conflict rule composes,
so it is required whenever the lock is taken at all. `holding r { … }` narrows
the extent inside a body and is optional.

### The four rules

1. **`owns(r)` with no block** means the body is the section. The function-scoped
   case is the sugar, exactly as a bare `requires P` is sugar for
   `requires { P; }`.
2. **A `holding r` block requires `owns(r)` in the row.** Otherwise it is a parse
   error, by the same mechanism that puts `asks` inside `interleaves`: the row
   must be honest, and a caller cannot see a body.
3. **The row is an upper bound.** A `holding` block under an `if` is fine — the
   row says the lock may be taken, not that it is.
4. **Two or more `owns` atoms require blocks.** With one lock the order is
   trivial. With two, a bare row leaves the acquisition order unstated, so it
   cannot be cleared for deadlock:

```
error: `transfer` takes `owns(src), owns(dst)` with no `holding` blocks —
       the acquisition order is unstated and cannot be checked for ordering
```

### The obligation

For a `lock r guards T`, the guarded type's invariant is **assumed on entry to a
section and must be proved on exit**, and is not assumed between. That is the
standard concurrent-separation-logic reading: you need to break the invariant to
do the update.

In case 1 the section is the whole body, so the obligation reduces to two clauses
that already exist —

```
an implicit  requires  keeps(T)     at entry
an implicit  ensures   keeps(T)     at exit
```

— with no new construct at all. In the block case it is one derived obligation at
the block's edges, deriving from the `lock … guards …` declaration rather than
from anything written at the block, so no new clause syntax is needed either.
Loops already show the language annotating a block, so this is not a new
syntactic category. Thermite has no `assert` and no proof blocks (verified: zero
occurrences), and neither form needs one.

### Why both, rather than the function alone

An earlier draft proposed function scope only, on the grounds that it needs no
new machinery and keeps every critical section visible in a signature. Two things
are wrong with that.

**Factoring is expensive here.** Narrowing a section by extracting a function
costs a full contract — `requires`, `ensures` and the row are all mandatory — so
scoping-only functions carry real signature noise. What is cheap in Rust is not
cheap in Thermite.

**Function scope cannot express the ordering this document's own open question
asks for.** `! owns(a), owns(b)` does not say which is taken first, so a deadlock
check has nothing to work with. Nested blocks state it structurally:

```thermite
holding a {
  holding b { … }        // a before b
}
```

So blocks are what make a region partial order checkable, rather than a
convenience that complicates it. And because a block is lexical, the extent stays
a syntactic property: reentrancy is containment — no call lexically inside a
`holding r` block may reach a function whose row carries `owns(r)` — rather than
a dataflow question. That would only become flow-sensitive with separate
acquire and release statements, which this does not propose.

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
  `owns(r)`? The answer is no, and rule 2 above makes it checkable by
  containment rather than by dataflow.
- **Ordering.** `owns(a), owns(b)` in one function and `owns(b), owns(a)` in
  another deadlocks, and today both typecheck. Rule 4 makes the order *stated*;
  it does not yet make it *checked*. Checking it needs a region partial order,
  which the effect-rows RFC also wants, and one order would close both at once.
  What this document contributes is that the order is now written down somewhere
  a checker could read.
