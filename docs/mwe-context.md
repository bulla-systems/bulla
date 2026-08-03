# MWE: the privilege state machine

The first buildable increment (T0). Requires no language work.

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

The three transitions to port, with the signatures `context.rs` has. Thermite
has no `impl` blocks, so these are free functions taking the context by value and
returning the new one. It also has **no implication operator**: `==>` is not in
the grammar, and a conditional postcondition is written `!a || b`. Payloads are
projected with `match` in `ens` rather than `.is_ok()` or `.unwrap()`, neither of
which exists.

```thermite
fn enter(ctx: UserContext, cap: Capability) -> Result<TrapFrame, ContextError>
  req true
  ens match result {
        Ok(f)  => f.privilege == Privilege::User
                  && f.generation == ctx.generation
                  && f.context == ctx.id,
        Err(e) => !ctx.runnable || e != ContextError::NotRunnable,
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
which is why it survives. See [G4](language-gaps.md#g4-struct-fields-of-user-declared-types).

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
  [G2](language-gaps.md#g2--no-concurrency-semantics).

## Expected certificate

```
P1  all / complete   / solver  @ to_platform(x86_64-pc-uefi-smp-v1)
P2  all / complete   / solver  @ to_platform(x86_64-pc-uefi-smp-v1)
```

`to_platform` rather than `e2e` because the transition bodies are registry
boundaries. `solver` rather than `lean-checked` unless the clauses land in a
reconstructible fragment, which is worth checking: these are equality and
implication claims over fixed-width integers and enums, which is QF_LIA
territory. If reconstruction applies, the trust coordinate improves to
`lean-checked` and no other coordinate changes.

## Acceptance

1. `context.th` compiles and certifies with P1 and P2 discharged
2. The generated code replaces `context.rs` in the boot path
3. The QEMU gate still passes the full 1/2/4/8-CPU matrix plus AP-failure and
   reboot
4. The published image carries a certificate naming P1, P2, their tuples, and
   the boundary set they close against
5. A broken transition, resuming with `Kernel` privilege, is rejected at check
   time, with the counterexample recorded in the test suite as a pinned
   regression

Criterion 5 carries the weight. A verification claim that has never been seen to
fail is not yet evidence.
