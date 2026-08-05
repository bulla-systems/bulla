# Invariant-guarded shared state

**Rung 4.** Kind: extension reusing `inv`.

## Summary

[verified effect rows](verified-effect-rows.md) permits only disjoint concurrent access.
This permits *shared* access, serialised, with the invariant holding at every
boundary.

The observation that makes it small: **a resource invariant is a struct
invariant.** `inv` already exists and already means "always true of this type".
The only new thing is a scope in which it may be temporarily false.

## Proposal

```thermite
struct Counter { n: u64 } inv n <= MAX

lock counters guards Counter;

fn bump(c: &mut Counter) -> ()
  req  c.n < MAX
  ens  final(c).n == c.n + 1
  fx   owns(counters)
```

`lock NAME guards TYPE;` is a new item form. It keeps the locking concern out of
the type declaration — the struct stays a plain struct with a plain invariant.

`owns(r)` joins `read(r)` and `write(r)` as a third mode: exclusive, established
dynamically. It does not conflict statically with anything, because exclusion is
achieved at runtime.

## The rule

The `inv` may be broken **inside** the critical section and must be restored
before release. That is the standard concurrent-separation-logic reading of a
resource invariant, and it is what makes the pattern useful: you need to break
the invariant to do the update.

## Metatheory

Concurrent separation logic (O'Hearn and Brookes, 2004). Mechanised repeatedly,
and the pinned Verus ships `vstd/invariant.rs` and `vstd/rwlock.rs`, so the
substrate is present.

## Open questions

- **Reentrancy.** Does holding `owns(r)` permit calling something that also wants
  `owns(r)`? The simple answer is no, and it should be stated rather than
  discovered.
- **Ordering.** `owns(a), owns(b)` in one function and `owns(b), owns(a)` in
  another deadlocks and both typecheck. Same gap as the effect-rows RFC; a region partial
  order would close both at once.
