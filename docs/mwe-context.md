# MWE: the privilege state machine

> **Superseded 2026-08-04, kept as a record.** This document specified T0 as a
> port of `kernel/src/context.rs`. That port is stopped. The upstream file is
> being withdrawn, and its shape — records nested inside records — is what made
> the attempt hit [G4](language-gaps.md#g4-struct-fields-of-user-declared-types)
> and five further gaps.
>
> What survives: the five properties P1–P5 are still the right claims for an
> execution-context subsystem, which [the architecture](architecture.md#4-applying-the-test)
> keeps IN the verified core. What changes is that the types get designed for
> Thermite rather than transcribed from Rust, per
> [§5 of the architecture](architecture.md#5-the-data-model).
>
> The findings recorded below — the gap set, the corrected `enter` signature, and
> the P3–P5 discovery — are why the architecture pass happened, so the document
> stays.

## Why this one

The verified payload in the prior work reads a clock and returns a field, with
the postcondition `result > 0`, against an implementation returning the literal
`1_000_000`. That is a link-integrity probe.

This MWE replaces it with a claim that is:

- a kernel-security property: privilege non-escalation
- expressible today, using enums with payloads, structs of fixed-width integers
  and booleans, and struct invariants, all shipped in Thermite
- already exercised by the boot path, since `setup_user_code`,
  `install_syscall_entry`, and the ring-3 syscall and fault handling run under
  the QEMU gate
- falsifiable in concrete terms, since a wrong transition is a specific register
  state rather than a stuck goal

Source: port [`kernel/src/context.rs`](../kernel/src/context.rs), forked from
upstream's `thermite-kernel/src/context.rs`. Checked against the forked file
rather than the survey: 193 lines, zero collections, zero generics, zero
`unsafe`.

## The claims

**P1, privilege non-escalation.** A context entered as `User` is never resumed
with `Kernel` privilege.

**P2, generation safety.** A context whose generation does not match the current
epoch is never resumable.

**P3, no kernel address.** A user context is never created holding an
instruction or stack pointer at or above `0x0000_8000_0000_0000`.

**P4, canonical addresses.** Both pointers satisfy the x86-64 canonical form.

**P5, stack alignment.** The stack pointer is 16-byte aligned.

> **P3–P5 added 2026-08-03.** The original three claims stopped at P1 and P2.
> P1 is carried structurally by the `TrapFrame` invariant, which is elegant and
> makes it close to free to prove: both constructors write the literal, so there
> is no transition that could violate it. P3–P5 come from `create`
> (`kernel/src/context.rs:58`) and have content — each is a range or bit
> predicate over a `u64` that a wrong constant falsifies concretely, which is
> what criterion 5 needs to bite against.

## Sketch

> **Corrected against the source on 2026-08-03.** The earlier sketch put a
> `privilege` field on `UserContext` and carried P1 as an invariant there. That
> field does not exist. `privilege` lives on `TrapFrame`, which is where the
> invariant belongs. The sketch also named functions (`resumable`, `on_trap`)
> that are not the ones `context.rs` has, and omitted the capability argument
> every transition takes. What follows now matches
> [`kernel/src/context.rs`](../kernel/src/context.rs).

```rust
enum Privilege { Kernel, User }

enum TrapOrigin {
  Interrupt(u8),
  Exception(u8),
  Syscall(u64),
}

struct Registers {
  instruction_pointer: u64,
  stack_pointer: u64,
  flags: u64,
  argument0: u64,
  result: u64,
}

struct UserContext {
  id: u32,
  address_space: u32,
  registers: Registers,
  generation: u64,
  runnable: bool,
}

struct TrapFrame {
  context: u32,
  origin: TrapOrigin,
  registers: Registers,
  privilege: Privilege,
  generation: u64,
}
  inv privilege == Privilege::User      // P1, structurally
```

P1 is carried by the invariant on `TrapFrame`, which is the strongest form
available: a `TrapFrame` that is not `User`-privileged cannot be constructed, so
no transition can produce one. Every function returning a `TrapFrame` owes the
invariant as a proof obligation.

The source supports this. Both constructors, `enter` and `trap`, write
`privilege: Privilege::User` as a literal, so the invariant holds by
construction. `resume` then checks `frame.privilege != Privilege::User` and
returns `WrongPrivilege`. Under the invariant that branch is unreachable, which
is a result in itself: the proof is stronger than the runtime check, and
discharging P1 should show the check to be dead rather than load-bearing.

The transitions to port, with the signatures `context.rs` has. Thermite has no
`impl` blocks, so these are free functions taking the context by value and
returning the new one. It also has **no implication operator**: `==>` is not in
the grammar, and a conditional postcondition is written `!a || b`. Payloads are
projected with `match` in `ens` rather than `.is_ok()` or `.unwrap()`, neither of
which exists.

> **`enter` corrected 2026-08-03.** An earlier sketch had
> `enter(ctx, cap) -> Result<TrapFrame, ContextError>`, which drops a mutation:
> `context.rs:97` sets `self.runnable = false` before returning the frame. With
> that lost, the `NotRunnable` guard at `:94` can never fire on a second call,
> and the enter/resume cycle P1 and P2 describe does not hold. `enter` has the
> same `&mut`-plus-return shape as `resume` and has to return both halves.

```thermite
fn create(cap: Capability, id: u32, space: u32, ip: u64, sp: u64)
    -> Result<UserContext, ContextError>
  req true
  ens match result {
        Ok(c)  => c.registers.instruction_pointer < 0x0000_8000_0000_0000   // P3
                  && c.registers.stack_pointer < 0x0000_8000_0000_0000      // P3
                  && canonical(c.registers.instruction_pointer)             // P4
                  && canonical(c.registers.stack_pointer)                   // P4
                  && c.registers.stack_pointer % 16 == 0                    // P5
                  && c.generation == 0 && c.runnable,
        Err(e) => true,
      }
  fx  pure

fn enter(ctx: UserContext, cap: Capability)
    -> Result<(UserContext, TrapFrame), ContextError>
  req true
  ens match result {
        Ok(pair) => !pair.0.runnable                       // the mutation, kept
                    && pair.0.generation == ctx.generation
                    && pair.1.privilege == Privilege::User
                    && pair.1.generation == ctx.generation
                    && pair.1.context == ctx.id,
        Err(e)   => ctx.runnable || e == ContextError::NotRunnable,
      }
  fx  pure

fn resume(ctx: UserContext, cap: Capability, frame: TrapFrame, value: u64)
    -> Result<UserContext, ContextError>
  req true
  ens match result {
        Ok(c)  => frame.generation == ctx.generation      // P2
                  && frame.context == ctx.id
                  && c.generation == ctx.generation + 1
                  && c.runnable,
        Err(e) => true,
      }
  fx  pure
```

`resume` carries P2: the only path to `Ok` runs through a generation equal to the
context's, and success advances the epoch by one. A false clause yields a
concrete `(frame.generation, ctx.generation)` pair. The `checked_add` in the
source makes `GenerationOverflow` a real branch needing its own clause rather
than an assumed-total increment.

`canonical` is a `spec fn` over the source's `is_canonical_x86_64`
(`kernel/src/memory.rs:419`), which is six lines of shifts and comparisons and
ports directly.

## What `create` pulls in

P3–P5 are the richer target, and they widen the dependency slice:

- `capability.rs` — `Capability`, `CapabilityKind` (19 unit variants), and
  `Rights`. `Rights` is a hand-rolled `pub struct Rights(u32)` with const bit
  constants and plain `union`/`contains` methods rather than a `bitflags!`
  macro, so it ports as a `u32` newtype with `&`-based predicates.
- `memory.rs` — `is_canonical_x86_64` only.

`Capability` has user-declared field types of its own, so
[G4](language-gaps.md#g4-struct-fields-of-user-declared-types) covers this slice
too. Widening the claim does not widen the blocker.

## The port exists and partly certifies

[`src/context.th`](../src/context.th) is the port, written 2026-08-03 against
the pin. It does not certify as a whole, and it was written anyway: attempting it
validated every non-struct part and surfaced six gaps that reading the reference
had not.

```
L3   Privilege · CapabilityKind · TrapOrigin · ContextError
L3   Registers · canonical · holds_rights
L3   create        ← P3, P4, P5 discharged for all inputs
L0   Capability · UserContext · TrapFrame       G4, upstream #122
L0   enter · resume                             G12, non-scalar equivalence probe
```

**P3, P4 and P5 are proven.** `create` reaches L3, so no user context is
constructed holding a kernel address, both pointers are canonical, and the stack
is 16-byte aligned — for all inputs, against a contract whose mutants die. P1 and
P2 are not, because the structs carrying them do not certify.

That is the T0 claim standing at three of five, and it is worth being precise
about which three: the ones that came from `create`, which the original MWE spec
omitted entirely.

The file carries two divergences from the source, both forced and both marked in
place: the `CapabilityKind` variants take a `Cap` prefix
([G8](language-gaps.md#g8-referencing-an-enum-variant-shadows-a-same-named-struct)),
and the generation guard is restated as `> MAX - 1`
([G10](language-gaps.md#g10-the-u64max-literal-lowers-to-u64max--1)).

One contract error found here was mine rather than Thermite's: `enter`'s `Err`
arm asserted `ctx.runnable || e == NotRunnable`, which a non-runnable context
with a bad capability falsifies, since it returns `WrongCapability`. Corrected to
the implication that holds.

## Blocked upstream

T0 was described here and in [the roadmap](roadmap.md) as needing no language
work. That is wrong, and the reason is three lines:

```thermite
struct Regs  { ip: u64 }
struct Frame { regs: Regs, generation: u64 }
```

`Frame` does not certify. The per-struct check harness emits the field without
weaving in the referenced declaration, so Verus reports
`error[E0425]: cannot find type 'Regs' in this scope`. The same happens for a
field of a user-declared *enum* type. A struct whose fields are all primitives
certifies at L3, so the failure is specific to user-declared field types.

This blocks the port directly: `UserContext` has `registers: Registers`, and
`TrapFrame` has `origin: TrapOrigin`, `registers: Registers` and
`privilege: Privilege`. Every one of them is a user-declared field type.

No conformance test in Thermite has a struct with a user-declared field type,
which is why it survives. See [G4](language-gaps.md#g4-struct-fields-of-user-declared-types), reported
upstream as [#122](https://github.com/dollspace-gay/Thermite/issues/122).

## What this does not prove

This section exists in every claim the project makes.

- **The assembly is not covered.** The ring transition is `SYSCALL`/`SYSRET` and
  trap-frame manipulation in the platform layer. Those are `#[boundary]`
  operations with assumed contracts. This MWE proves the model; the binding to
  the hardware sequence remains a trusted registry entry.
- **Scheduler choice is not covered.** The claim is that whatever context is
  picked cannot be resumed with escalated privilege or a stale generation.
- **Concurrency is not covered.** Two CPUs resuming contexts simultaneously is
  outside the model, and outside Thermite's expressiveness. See
  [G2](language-gaps.md#g2-no-concurrency-semantics).

## Expected certificate

```
P1  all / complete   / solver  @ to_platform(x86_64-pc-uefi-smp-v1)
P2  all / complete   / solver  @ to_platform(x86_64-pc-uefi-smp-v1)
P3  all / complete   / solver  @ to_platform(x86_64-pc-uefi-smp-v1)
P4  all / complete   / solver  @ to_platform(x86_64-pc-uefi-smp-v1)
P5  all / complete   / solver  @ to_platform(x86_64-pc-uefi-smp-v1)
```

`to_platform` rather than `e2e` because the transition bodies are registry
boundaries. `solver` rather than `lean-checked` unless the clauses land in a
reconstructible fragment, which is worth checking: these are equality, range and
bit predicates over fixed-width integers and enums, which is QF_BV and QF_LIA
territory. If reconstruction applies, the trust coordinate improves to
`lean-checked` and no other coordinate changes.

P4 is the one to watch: `is_canonical_x86_64` is two shifts and a comparison, so
it lands in bitvector reasoning rather than linear arithmetic, and the two
fragments do not always mix well in one query.

## Acceptance

1. `context.th` compiles and certifies with P1 and P2 discharged
2. The generated code replaces `context.rs` in the boot path
3. The QEMU gate still passes the full 1/2/4/8-CPU matrix plus AP-failure and
   reboot
4. The published image carries a certificate naming P1, P2, their tuples, and
   the boundary set they close against
5. Each of these deliberate breaks is rejected at check time, with the
   counterexample recorded as a pinned regression:

   | break | should fail |
   |---|---|
   | resume with `Kernel` privilege | P1 |
   | accept a frame whose generation differs | P2 |
   | widen the kernel-address bound to `0x0001_0000_0000_0000` | P3 |
   | drop the `is_canonical_x86_64` check on the stack pointer | P4 |
   | change the alignment mask from `0xf` to `0x7` | P5 |

   P1's break is the weakest of the five, because the `TrapFrame` invariant makes
   it unconstructible rather than unprovable. P3 and P5 are the ones where a
   wrong constant produces a concrete falsifying address.

Criterion 5 carries the weight. A verification claim that has never been seen to
fail is not yet evidence.
