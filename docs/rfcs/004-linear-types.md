# RFC-004 — Linear types

**Rung 5.** Kind: surface an existing capability.

## Summary

Thermite's declared types are **affine** — they move rather than copy, and reuse
is rejected:

```thermite
struct Tok { v: u64 }
fn take(t: Tok) -> u64 req true ens result == t.v fx pure { t.v }
fn twice(t: Tok) -> u64 ... { let a: u64 = take(t); let b: u64 = take(t); a + b }
```
```
error[E0382]: use of moved value: `t`
```

Affine gives *at most once*: you may drop. **Linear** gives *exactly once*: you
may not. The gap between them is precisely the gap between a safety property and
a liveness one.

## Why the kernel needs it

Reusable allocation. A page is granted, used, returned, granted again. The
property "no page is in two grants at once" is maintained **by construction** if
grants cannot be duplicated *or forgotten* — and affine types only give the
first.

Below this rung the set of processes is fixed at boot or grows monotonically
until memory is exhausted. Above it, `fork`, `exec`, demand paging and
copy-on-write are all expressible. It is the rung where a verified Unix kernel
becomes conceivable rather than a verified box around an unverified one.

## Proposal

An attribute, matching the existing `#[sealed]` / `#[boundary]` style:

```thermite
#[linear] struct Grant { frame: u64, generation: u64 }

fn alloc(a: Allocator) -> (Allocator, Grant)
  req  a.free_count > 0
  ens  result.1.frame < a.limit
  fx   pure

fn release(a: Allocator, g: Grant) -> Allocator
  req  g.generation == a.generation
  ens  result.free_count == a.free_count + 1
  fx   pure
```

Rule: a binding of a `#[linear]` type must be consumed on **every** path. That is
the move analysis Rust already performs, minus permission to drop.

## Metatheory

Linear logic (Girard, 1987); linear and non-linear types coexisting in one
language is Benton's LNL (1994). Settled.

More to the point, **the pinned Verus already ships it**: `vstd/tokens.rs`
provides linear ghost tokens, and `Tracked<T>` is linear ghost state. This RFC is
surface syntax over machinery that exists.

## The caveat that must not be discovered late

From `vstd/tokens.rs` itself:

> the `tokenized_state_machine!` macro creates **trusted** implementations of all
> these traits… the properties of these types is still assumed by the Verus
> macro, so they're still mostly trusted.

A release rule blocking axioms and `assume` needs a position on that trusted
core.

## Open questions

- Interaction with `fx panic` — is a linear value dropped on abort, and does that
  break the discipline or merely end the program?
- Whether linearity belongs on the type or the binding. The type is simpler; the
  binding is more flexible.
