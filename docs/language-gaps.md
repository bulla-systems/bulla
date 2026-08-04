# Language gaps

What Thermite cannot yet express that Bulla needs, with scope estimates. These
belong upstream in [Thermite](https://github.com/dollspace-gay/Thermite).

Baseline at Thermite `84d276e7`, the [upstream pin](upstream-pin.md). Counts
below were re-checked against the forked tree on 2026-08-02. Three of them were
wrong in the original survey and are corrected here.

---

## G1: `Map` needs `remove` and iteration

**Status upstream:** reported as [#123](https://github.com/dollspace-gay/Thermite/issues/123).

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

### The audit, run 2026-08-03

Every `BTreeMap` operation the models call, against the shipped
`insert`/`get`/`contains_key`/`len` surface. 257 call sites: 150 covered, 107 not.

The raw 42% overstates it, because two of the uncovered operations are mutation
idioms rather than capabilities. `get_mut` (48 sites) and `entry` (4) are
read-modify-write on a `&mut` binding, which in a value-semantics language is
`get` followed by `insert`. `is_empty` (2) is `len() == 0` and `clear` (2) is a
fresh `Map::new()`. None of those need anything from the lowering.

What is left is two genuine capabilities:

| missing | sites | where |
|---|---|---|
| `remove` | 24 | frame 12, dma 4, irq 2, memory 2, smp 2, services 2 |
| iteration (`iter`, `values`) | 25 | frame 10, memory 5, scheduler 4, smp 2, sync 2, services 2 |

Per tier, which is what decides the roadmap:

| tier | models | needs |
|---|---|---|
| T1 capability ledger | `capability` | nothing — its only uncovered op is `get_mut` |
| T2 frame / memory | `frame`, `memory` | `remove` and iteration |
| T3 irq / device / dma | `irq`, `dma`, `device` | `remove` |
| T4 smp / sync / atomic | `smp`, `sync`, `atomic` | `remove` and iteration |

**G1 is a real gap, and smaller than first described.** It is two operations, not
a missing `Map`. T1 is not blocked by it at all, which the original framing had
wrong in the other direction. Revocation needs `remove`; the schedulers and
allocators need to traverse.

Whether iteration is even expressible under the bounded Vec-of-pairs backing is
the open design question — a `forall` over the domain may serve the contracts
without an iteration primitive in exec position. That is upstream's call.

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
