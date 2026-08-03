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

> Types below follow `context.rs` as surveyed. Field names must be confirmed
> against the source before implementation. This is a specification rather than a
> transcription.

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
  privilege: Privilege,
}
  inv privilege == Privilege::User      // P1, structurally
```

P1 is carried by the struct invariant, which is the strongest form available: a
`UserContext` that is not `User`-privileged cannot be constructed, so no
transition function can produce one. Every function returning a `UserContext`
owes the invariant as a proof obligation.

```rust
fn resumable(ctx: UserContext, epoch: u64) -> (r: bool)
  req true
  ens r ==> ctx.generation == epoch          // P2
  ens r ==> ctx.runnable
  fx pure
{
  ctx.runnable && ctx.generation == epoch
}

fn on_trap(ctx: UserContext, origin: TrapOrigin) -> (out: UserContext)
  req ctx.runnable
  ens out.privilege == Privilege::User       // P1, restated at the boundary
  ens out.generation == ctx.generation       // a trap does not advance the epoch
  fx pure
{ /* ... */ }
```

`resumable` is a total function whose postcondition constrains it to return true
only with a matching generation and a runnable context. The kernel's resume path
calls it, and a false clause here yields a concrete `(generation, epoch)` pair.

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
