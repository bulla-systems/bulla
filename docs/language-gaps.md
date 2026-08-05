# Language gaps

What Thermite cannot yet express that Bulla needs, with scope estimates. These
belong upstream in [Thermite](https://github.com/dollspace-gay/Thermite).

Baseline at Thermite `84d276e7`, the [upstream pin](upstream-pin.md). Counts
below were re-checked against the forked tree on 2026-08-02. Three of them were
wrong in the original survey and are corrected here.

---

## G1: `Map` needs `remove` and iteration

> **Corrected 2026-08-03.** This section previously claimed `Map` parses but does
> not lower, and that 13 of 19 model files were blocked on
> `REQ-LOWER-COLLECTIONS-MAP-VSTD`. **That was wrong.** It read a deferred
> alternative implementation as a missing capability. Recorded rather than
> deleted, because the error shape — treating a `not_started` REQ as a blocker
> without checking what it actually defers — is one this project should be able
> to recognise again.

**`Map` lowering ships.** `conformance/map_kv.th` upstream is a working
`Map<u64, u64>` — `Map::new()`, `insert`, `get`, `contains_key`, `len` — over a
bounded Vec-of-pairs `TMap` backing, grounded against real Verus by
`forge/tests/map_conformance.rs`. Contracts over it are cage-admissible through
`contains_key`.

| REQ | status |
|---|---|
| `REQ-SYNTAX-MAP-TYPE`, `REQ-SYNTAX-MAP-METHODS` | shipped |
| `REQ-LOWER-MAP-WRAPPER` (bounded wrapper) | **shipped** |
| `REQ-LOWER-MAP-RIPPLE`, `REQ-LOWER-MAP-ERRORS` | shipped |
| `REQ-SPEC-VALIDATOR-MAP-CAGE` | shipped |
| `REQ-LOWER-COLLECTIONS-MAP-VSTD` | `not_started` — a deferred **thin `vstd::map` alternative**, not the capability. Its registry note: *"bounded Vec-of-pairs Map lowering is tracked separately."* |

### What is actually open

Whether the shipped bounded wrapper covers what the kernel models do with
`BTreeMap`. Thirteen of nineteen model files use one:

```
device 6 · smp 5 · scheduler 5 · frame 5 · dma 5 · irq 4
sync 3 · services 3 · memory 3 · event 3 · policy 2 · capability 2 · atomic 2
```

The visible shipped surface is `insert` / `get` / `contains_key` / `len` over
primitive keys. Three things need measuring against actual usage:

1. **Removal** — no `remove` appears in the builtin method allowlist. Capability
   revocation and frame free almost certainly need it.
2. **Iteration** — no iteration primitive is visible. Scheduler and IPI fan-out
   traverse their maps.
3. **Non-primitive keys and values** — the conformance case is `u64 → u64`; the
   models key on newtypes and store structs.

### The audit, corrected 2026-08-03

> **The first run of this audit was wrong and its numbers were published
> upstream.** It summed two overlapping regexes, so every `self.field.method()`
> call counted twice: 257 sites reported against 130 actual, with every
> per-operation figure exactly doubled. It also listed `len` as available in exec
> position, which it is not. Corrected below against a receiver-typed,
> position-deduplicated count, which agrees operation-for-operation with an
> independent measurement from the Thermite side. The upstream issue carries the
> correction.

**The shipped exec surface is three operations.** From `emit_one_map_wrapper` in
`thermite-lower/src/lower.rs`:

| | |
|---|---|
| executable | `insert`, `get`, `contains_key` |
| spec-only | `len`, `spec_contains_key`, `spec_dom`, `well_formed` |

`len` is a `pub open spec fn`, so there is no executable size or emptiness test.
`remove`, `iter`, `values` and `keys` appear nowhere in `thermite-syntax`,
`thermite-lower` or `thermite-spec`.

**The models call twelve distinct operations across 130 sites:**

```
insert 37 · get 27 · get_mut 24 · remove 12 · contains_key 11 · iter 9
values 4 · entry 2 · clone 1 · clear 1 · is_empty 1 · take 1
```

Rewritable against the shipped surface: `get_mut` and `entry` become
`get`/modify/`insert`, since `insert` overwrites; `clear` becomes a rebind;
`clone` and `take` are local.

Not rewritable:

| missing | sites | files |
|---|---|---|
| `remove` | 12 | dma, frame, irq, memory, services, smp |
| iteration (`iter`, `values`) | 13 | frame, memory, scheduler, services, sync |
| `is_empty` | 1 | memory — blocked too, because `len` is spec-only |

Together they touch **8 of the 19 model files**.

**So G1 is surface coverage rather than existence.** `Map` lowers and works; it
is missing two operations the kernel models need. Per tier: T1 needs neither and
is clear, T3 needs `remove`, and T2 and T4 need both.

Whether iteration needs an exec-position primitive is the open design question.
Every use in the models is a fold or a search whose contract is a `forall` over
the domain, and `spec_dom` already exists, so the contracts may be writable
without an iterator.

---

## G2: no concurrency semantics

Status upstream: absent, rather than incomplete.

The effect row is `pure` or a subset of
`{read(path), write(path), net(domain), alloc, time, rand, panic, diverge}`,
plus `platform(domain)` added by the kernel work. There is no concurrency
effect, no design document, and no requirement covering it. Every occurrence of
"atomic" in the requirements registry refers to atomic *file publication*.

The kernel is concurrent throughout: application-processor startup,
inter-processor interrupts, TLB shootdown with acknowledgment masks, per-CPU
state, lock protocols, and IPC on the hot path in a microkernel.

Scope: large, and research rather than implementation. Three directions:

1. Ownership-based: one CPU may hold a capability at a time, so races become type
   errors. Cheapest, fits the existing capability model, and cannot express
   lock-free protocols.
2. An explicit atomic effect plus linearizability contracts. The richest option
   and the most work.
3. A sequential model plus an interleaving obligation: verify sequentially, then
   discharge a separate obligation that interleavings preserve the invariant.

For precedent: seL4's original verification was uniprocessor with interrupts
largely disabled in-kernel, sidestepping concurrency, and its SMP story came
later and weaker. CertiKOS took the layered-refinement route for a concurrent
kernel. This is a hard problem and should not be scoped optimistically.

Blocks T4, and with it the monolithic-scope ambition.

---

## G3: no user-defined generics

Status upstream: by design. `surface-grammar.md` REQ-8 permits exactly one
builtin generic application `NAME<T>`, and AC-3 forbids a production for
struct-as-Rust-generics.

The kernel models use const generics. `kernel/src/policy.rs:16` has
`pub struct ActionBatch<const N: usize>`, and `storage.rs` and `sync.rs` use
light generics.

Scope: medium-to-large if solved properly.

Workaround: hand-monomorphize at fixed N. A kernel has fixed limits throughout
(`maximum_cpus = 64`, `scheduler_tasks = 4096`), so this costs little. G3 is a
papercut and should not be prioritized over G1.

---

## G4: struct fields of user-declared types

**Status upstream:** reported as [#122](https://github.com/dollspace-gay/Thermite/issues/122). Found here on 2026-08-03 while starting T0.

A `struct` whose field type is another user-declared `struct` or `enum` does not
certify. Three lines reproduce it:

```thermite
struct Regs  { ip: u64 }
struct Frame { regs: Regs, generation: u64 }
```

```
error[E0425]: cannot find type `Regs` in this scope
  |     pub regs: Regs,
```

**Scope corrected 2026-08-04: this covers enums too.** The upstream report
described a struct-field problem. Measured against enum variants, both payload
forms fail identically:

```thermite
enum Ev  { Header { r: Regs }, Done }    // error[E0425]
enum Ev2 { Header(Regs), Done }          // error[E0425]
```

So the accurate statement is that **the type graph must be one level deep**: no
declared type may appear inside any other declared type, in any position. An enum
variant carrying only primitives certifies at L3, which is what makes a
transition-system style workable at all today.

The per-struct check harness emits the field declaration without weaving in the
declaration it references. A struct whose fields are all primitives certifies at
L3, so the fault is specific to user-declared field types, and the containing
function's own obligations still discharge. It is the struct's harness that
fails, which fails the project.

No `.th` in Thermite's conformance corpus has a struct with a user-declared field
type, which is why this survives. `REQ-LOWER-ADT-STRUCT` and
`REQ-LOWER-L1-STRUCT-INVARIANTS` both exist and neither covers it.

**Scope:** small. It is a missing dependency in harness construction rather than
a semantics question.

**Blocks:** every tier, which is what makes it the critical path rather than a
T0 detail. Counted across the forked models on 2026-08-03, **11 of the 19 files**
declare a struct with a user-declared field type:

```
event 5 · atomic 4 · context 4 · dma 4 · capability 3
memory 2 · registry 2 · scheduler 1 · services 1 · smp 1 · sync 1
```

`context.rs` is T0, `capability.rs` is T1, `dma.rs` is T3, and
`atomic`/`sync`/`smp` are T4. Modelling state as a record holding an enum or
another record is the ordinary shape for these subsystems, so it is not a corner
they can be written around.

With [G1](#g1-map-needs-remove-and-iteration) reduced to an unmeasured
question, G4 is the only confirmed blocker in this document, and it sits upstream
of every tier.

### G4b: `inv` does not bind the receiver for `is`

Filed with G4 in [#122](https://github.com/dollspace-gay/Thermite/issues/122).

A second, narrower fault in the same area. A struct invariant written with the
variant-test operator loses its receiver:

```thermite
struct Frame { privilege: Privilege } inv privilege is User
```

```
error[E0425]: cannot find value `privilege` in this scope
  |     (privilege is User)
  |      help: you might have meant to use the available field: `self.privilege`
```

Writing the same invariant as `inv privilege == Privilege::User` compiles, so
there is a workaround and the fault is confined to `is` in an `inv` clause.
Upstream commit `b8dc3947`, "Bind struct invariant fields through unary
operators", addressed the neighbouring case, which suggests the binding pass
enumerates expression forms and `is` was missed.

---

## G5: no implication operator

**Status upstream:** by design, as far as the grammar shows.

Thermite's binary operator inventory has no `==>`. Conditional postconditions are
written `!a || b`. This is a readability cost rather than an expressiveness one,
and it bites hardest in exactly the contracts this project writes, where most
clauses are of the form "if the result is `Ok`, then ...".

Worth noting that `==>` appears in a comment in `conformance/parse_u64.th`
describing a contract in prose, which is how it got into an earlier draft of
[the MWE](mwe-context.md) as though it were syntax.

**Scope:** small, and a candidate for an upstream RFC: surface sugar desugaring
to `!a || b`, with no change to the proof obligations.

---

## G13: no linear types, so a grant can be dropped

**Status upstream:** not a defect. Thermite never claimed linear types; this is a
requirement [the architecture](architecture.md#3-making-invariants-local-ownership-as-the-lever)
places on the language, recorded rather than filed.

Declared types are affine: they move rather than copy, and reuse is rejected.

```thermite
struct Tok { v: u64 }
fn take(t: Tok) -> u64 req true ens result == t.v fx pure { t.v }
fn twice(t: Tok) -> u64 ... { let a: u64 = take(t); let b: u64 = take(t); a + b }
```
```
error[E0382]: use of moved value: `t`
```

That is what makes an ownership grant unforgeable, and it is the mechanism the
meso position depends on. What is missing is the other half: nothing requires a
grant to be *returned*. Affine types permit dropping; linear types would not.

The consequence is a clean split in what the architecture can claim. Duplication
is a safety property and is enforced. Leaking is a liveness property and is not,
so resource exhaustion sits outside the model and the assurance claim says so.

**Scope:** large, and a language-design question rather than a bug. Worth raising
only once there is a verified subsystem whose grants it would apply to.

---

## Found by attempting the port

`src/context.th` is a real 200-line port of `kernel/src/context.rs`, written and
checked against Thermite at the pin on 2026-08-03 while
[#122](https://github.com/dollspace-gay/Thermite/issues/122) is outstanding. It
does not certify, which was expected. Six further gaps surfaced on the way, none
of which reading the language reference would have found.

Where it got to:

```
L3   Privilege · CapabilityKind · TrapOrigin · ContextError   (enums)
L3   Registers                                                (primitive-only struct)
L3   canonical · holds_rights                                 (spec fns)
L3   create                                                   ← P3, P4, P5 discharged
L0   Capability · UserContext · TrapFrame                      G4
L0   enter · resume                                            G12
```

`create` certifying is the substantive result: no kernel address, canonical
addresses, and 16-byte stack alignment are proven for all inputs, against a
contract whose mutants die.

### G6: an integer literal in `dec` has no inferable type

```thermite
spec fn canonical(address: u64) -> bool
  dec 0
```
```
error[E0283]: type annotations needed
   | decreases 0
   | cannot infer type of the type parameter ... on `spec_literal_integer`
```

Every `spec fn` in the conformance corpus uses a parameter as its measure
(`dec l`, `dec r`, `dec xs.len()`), so a constant measure is unreached. Naming a
parameter works and is the workaround.

### G7: `==` on a user enum works in spec position and fails in exec position

```thermite
fn f(k: K) -> bool ... { if k == K::A { .. } }   // error[E0369]
fn f(k: K) -> K ... ens result == K::A { K::A }  // L3
```

The lowering does not put `PartialEq` on user enums in exec code. `is Variant`
works in exec position and is the workaround.

Read together with [G4b](#g4b-inv-does-not-bind-the-receiver-for-is) this is a
neat complementary pair: an `inv` clause takes `==` and not `is`, and an exec
body takes `is` and not `==`.

### G8: referencing an enum variant shadows a same-named struct

```thermite
enum Kind { Thing, Other }
struct Thing { id: u32 }
// in one fn: discriminate on Kind::Thing, then construct Thing { id }
error[E0559]: variant `Kind::Thing` has no field named `id`
```

Construction resolves to the variant. Neither qualifying (`k is Kind::Thing`)
nor using `match` avoids it; only renaming does. Constructing the struct in a
function that never mentions the variant is fine.

This is not hypothetical for a port: `CapabilityKind::UserContext` and
`struct UserContext` are both names `kernel/src/context.rs` uses, and the two
meet in every transition. `src/context.th` prefixes the variants to get past it,
which is a divergence from the source it is supposed to mirror.

### G9: `spec fn` is not callable from exec position

```
error: cannot call function `holds_rights` with mode spec
```

The language reference describes spec functions as "total, terminating,
executable", and the lowering emits Verus `spec fn`, which is ghost-only. A
predicate needed in both a contract and a body has to be written twice: once as
a `spec fn` and once inline.

### G10: the `u64::MAX` literal lowers to `u64::MAX + 1`

```thermite
x == 18446744073709551615     // written
if ctx.generation == 18446744073709551616 {   // emitted
error: integer literal out of range U(64)
```

`18446744073709551614` lowers correctly, as do small literals, so this is an
off-by-one at the boundary rather than general literal breakage. It bites any
saturation or overflow guard, which is where `u64::MAX` naturally appears —
`context.rs` guards its generation counter with `checked_add`. Restating the
guard as `> MAX - 1` is the workaround.

### G11: user structs have no `Copy`, so a field cannot be read twice

```
error[E0382]: use of moved value: `ctx.registers`
```

`enter` reads `ctx.registers` into both the updated context and the trap frame,
which the source does freely because `Registers` derives `Clone, Copy`.
Rebuilding the literal field by field is the workaround, and it scales badly:
five fields here, and the reason `enter` is longer in `.th` than in Rust.

### G12: the mutation-equivalence probe supports only scalar returns

```
equivalence obligation supports only scalar (u32/u64/usize/bool) returns;
`resume` returns a non-scalar type (equivalent-mutants.md OQ-1)
survivor COUNTED, not excluded
```

Every transition in a state machine returns `Result<Struct, Error>`. For those,
equivalent mutants cannot be probed, so they are counted as survivors and the
kill ratio is biased down: `resume` scores 9/18 against the §7 floor.

This is a bias rather than a bar — `create` returns `Result<UserContext, _>` too
and cleared the floor. But it means a non-scalar-returning transition needs a
contract strong enough to overcome the counted survivors, and the failure it
reports names the contract rather than the probe, which sends you looking in the
wrong place.

---

## G14: a loop has no `diverge` exemption, so an infinite loop needs a false measure

**Status upstream:** not filed. Found on 2026-08-04 by probe during the surface
pass.

A recursive `fn` may decline to prove termination by declaring the effect, and
the checker says so itself:

```
recursive function `countdown` must have a decreases clause — a `fn` that calls
itself MUST supply a `dec <measure>` so termination is proved (§4.1;
`.design/basis/10-recursion-tuples.md` REQ-2), UNLESS it declares `fx diverge`
```

Taking that exemption costs assurance rather than being free: the same function
certifies at **L1** with `fx diverge` where it would reach L3 with a measure.
That is a good design — divergence is available, priced, and visible in the
certificate.

The exemption does not reach loops. A loop requires `dec` even when the enclosing
function declares `fx diverge`:

```thermite
fn idle() -> u64
  req true
  ens result == 0
  fx diverge
{ let mut i: u64 = 0; while true inv i >= 0 { i = i + 1; } 0 }
```
```
forge: parse failed (1 error(s)):
  - function `loop` is missing the mandatory `dec` clause
```

Adding `dec 0` makes it certify at L1. So an intentionally infinite loop — a
scheduler idle loop, an event loop, the most ordinary construct in a kernel — is
only writable by supplying a measure that cannot strictly decrease, and the false
measure then sits in the source where a later reader will believe it.

Worth noting the asymmetry that is *not* a gap: `spec fn` requires a measure with
no exemption, recursive or not. That is correct, because a spec function is used
in logic and a non-total one would be unsound.

**Scope:** small. Extend the `UNLESS it declares fx diverge` exemption from
functions to the loops inside them, so an infinite loop is written by omitting
the measure rather than by faking one.

---

## Not gaps

The kernel models are `unsafe`-free, and enforced as such: the one occurrence of
the word in `kernel/src/lib.rs` is `#![forbid(unsafe_code)]` at line 2. The
original survey read that attribute as an instance of what it forbids and
reported "one `unsafe` in `lib.rs`".

Checked against the forked tree: zero `unsafe` blocks across all 19 model files,
no traits, and the only raw pointers are three ASCII signature strings in
`registry.rs` describing `memcpy`, `memmove` and `memset`. This is data-structure
and logic code, which is the kind Thermite handles.

The obstacle to verifying this kernel is collections and concurrency rather than
unsafety or hardware.
