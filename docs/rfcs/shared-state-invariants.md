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

## The scope of a lock is a function

The rule that the invariant may be broken inside the critical section is only
meaningful once the critical section has edges. This is where they are.

> **`! owns(r)` makes the function body the critical section.** The lock is held
> for the whole body and for nothing else.

Which reduces the new rule to two clauses that already exist. For a `lock r
guards T` and a function carrying `owns(r)`, the guarded type's invariant becomes

```
an implicit  requires  keeps(T)     at entry
an implicit  ensures   keeps(T)     at exit
```

and is *not* assumed anywhere between. That is the standard
concurrent-separation-logic reading — you need to break the invariant to do the
update — expressed with no new construct, no proof block, and no statement-level
annotation. Thermite has no `assert` and no proof blocks (verified: zero
occurrences), so a mechanism that needed either would not fit the language.

**The cost, stated rather than discovered:** a critical section is always a whole
function. A body that wants to hold the lock for part of itself has to factor
that part into its own function. That is a real constraint, and it buys something
— the extent of every critical section is visible in a signature rather than
buried in a body, which is the property that makes the extents auditable at all.
Kernel critical sections are short, so the constraint bites rarely, and where it
bites the factoring is the documentation.

A block form (`holding counters { … }`) would lift the constraint, and loops show
the language can annotate a block. It is the wrong trade here: it moves the
critical section out of the signature, and the whole value of `owns(r)` in the
row is that a caller can see it.

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
  `owns(r)`? The simple answer is no, and it should be stated rather than
  discovered. Function-scoped locks make this checkable: the call graph of an
  `owns(r)` function must contain no other `owns(r)` function.
- **Ordering.** `owns(a), owns(b)` in one function and `owns(b), owns(a)` in
  another deadlocks and both typecheck. Same gap as the effect-rows RFC; a region
  partial order would close both at once.
