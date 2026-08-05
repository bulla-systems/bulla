# Resource types

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
may not. The gap between them is the gap between a safety property and a liveness
one.

## Why the kernel needs it

Reusable allocation. A page is granted, used, returned, granted again. The
property "no page is in two grants at once" is maintained by construction if
grants cannot be duplicated *or forgotten*, and affine types only give the first.

Below this rung the set of processes is fixed at boot or grows monotonically
until memory is exhausted. Above it, `fork`, `exec`, demand paging and
copy-on-write are all expressible. It is the rung where a verified Unix kernel
becomes conceivable rather than a verified box around an unverified one.

## Proposal

A keyword rather than an attribute, because it changes what the item *is*:

```thermite
resource struct Grant { frame: u64, generation: u64 }

fn allocate(a: Allocator) -> (Allocator, Grant)
  ! pure
  requires  a.free_count > 0
  ensures   result.1.frame < a.limit

fn release(a: Allocator, g: Grant) -> Allocator
  ! pure
  requires  g.generation == a.generation
  ensures   result.free_count == a.free_count + 1
```

Rule: a binding of a `resource` type must be consumed on **every** path. That is
the move analysis Rust already performs, minus permission to drop.

`resource` rather than `linear` or `once`, per
[the surface conventions](surface-conventions.md): the keyword names what the
value *is*, and both halves follow from the kind — a copy of a resource is a
second claim on the same thing, and a resource you fail to release is a resource
leak.

## Contagion: a struct with a resource field is a resource

Unstated in the first draft, and the discipline does not survive without it. If
`Outer` holds a `Grant` and `Outer` may be dropped, then dropping `Outer` drops
the `Grant`, and every guarantee above is void. Linearity is contagious upward.

**Contagion is declared and checked, not inferred.** A struct or enum reachable
to a `resource` type must carry the keyword itself, and omitting it is an error
naming the field:

```thermite
resource struct Grant { frame: u64, generation: u64 }

struct Mapping { g: Grant, base: u64 }
```
```
error: `Mapping` has the resource field `g` and is not itself a `resource`
```

Inference would be less writing and worse. The property would then be invisible
at the declaration, and a reader deciding whether a type may be dropped would
have to close over every field's definition. This follows the shape the language
already uses for termination: prove it or declare it, but do not let it be
silent.

The rest of the rule, stated because each part has a way to go wrong:

**Enums.** A variant carrying a resource makes the enum a resource. The empty
variants do not exempt it — `Maybe::None` is fine to drop, but the type has to be
`resource` because `Maybe::Some(g)` is not, and dropability is a property of the
type.

**Generic carriers.** `Result<Grant, u64>` and `Vec<Grant>` are resources. This
one is load-bearing rather than pedantic: `allocate` returns
`Result<(Allocator, Grant), u64>` in the architecture's own signatures, so the
error path is precisely where a grant would go missing.

**Downward, nothing.** A `resource` struct does not make its `u64` fields
anything. Contagion is upward only.

**Destructuring is consumption of the container, not of the parts.** Taking a
`resource` struct apart is allowed, and it hands you every resource field as its
own obligation. The container is consumed; the parts each still need consuming.

**Not reachable today.** [G4](../language-gaps.md#g4-struct-fields-of-user-declared-types)
means a declared type cannot be a field of another declared type, so no struct
can have a resource field and the rule is unenforceable until that lifts. Worth
writing now for the reason the architecture gives for designing the composed
model anyway: a rule derived before the constraint lifts is a rule; a rule
discovered after is a migration.

## Abandoning one is an operation, not a hole

Type-level linearity is inflexible by construction: a `Grant` must be consumed
even on a path where abandoning it is the correct thing to do. Teardown,
shutdown and abort all want that, and a discipline with no answer for them gets
worked around rather than followed.

The answer is to make abandonment explicit and visible in the row:

```thermite
fn shutdown(g: Grant) -> ()
  ! forgets(heap)
  requires  nothing
  ensures   nothing
{ forget(g) }
```

`forget(g)` discharges the obligation without consuming the resource, and
`forgets(r)` records it as a state effect on the region the resource came from.
So the escape exists, it is counted, it appears in every transitive caller's row
by the composition law, and a release rule can refuse it the way TMK's refuses
`#[boundary]`.

**This is also the answer to the `panic` question**, which is otherwise a hole in
the whole rung. An abort drops every live binding, including resources, so the
guarantee is *exactly once unless the program dies*. With an explicit
abandonment operation, that stops being an unstated caveat and becomes a claim
about a specific effect: a function carrying `panic` and holding a resource is
performing an implicit `forget`, and the row should say so rather than the
guarantee quietly weakening. Whether `panic` therefore implies `forgets(r)` for
every live resource, or whether the two are simply incompatible in a release
build, is the remaining choice — but it is now a choice between two stateable
rules rather than an omission.

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

## Settled here, recorded as choices

**Linearity is on the type, not the binding.** The binding is more flexible and
is closer to the substrate — Verus's `tracked` is a mode on a binding, not a
property of a type — so the lowering will insert `tracked` at each use. The type
wins anyway, because contagion is not optional and only types can state it: a
field is not a binding, so "a struct with a resource field is a resource" has
nothing to attach to under the binding reading. The flexibility that argument
gives up is returned by `forget` above.

**What remains open** is the narrower half of the `panic` question: whether
`panic` implies `forgets(r)` for every live resource, or whether a release build
simply refuses the combination.
