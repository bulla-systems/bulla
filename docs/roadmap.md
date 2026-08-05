# Roadmap

> **Superseded as the primary roadmap, 2026-08-04.** [The ladder](the-ladder.md)
> is where the plan now lives: rungs of proof capability, each with the kernel it
> buys and the language work it needs. This document's tier table is retained
> because the blockers it records are accurate, and because T0–T4 are still the
> subsystem-level increments once a rung is reached.

Five tiers, each naming its blocker. A tier is SHIPPED when it is end-to-end
functional with a non-test consumer, tests, and verification evidence, and
NOT STARTED otherwise, with a concrete open prerequisite. There is no "in
progress" status, since that is where overclaiming lives.

| tier | subsystem | property worth proving | blocker | status |
|---|---|---|---|---|
| T0 | privilege / context | privilege non-escalation and generation safety, plus no kernel address, canonical addresses and stack alignment at creation | [G4](language-gaps.md#g4-struct-fields-of-user-declared-types) / upstream [#122](https://github.com/dollspace-gay/Thermite/issues/122), and [G12](language-gaps.md#g12-the-mutation-equivalence-probe-supports-only-scalar-returns) | NOT STARTED |
| T1 | capability ledger | no capability escalation; generation-safe revocation | [G4](language-gaps.md#g4-struct-fields-of-user-declared-types) only; the G1 audit clears it | NOT STARTED |
| T2 | frame / memory | no physical frame is double-allocated | [G1](language-gaps.md#g1-map-needs-remove-and-iteration) / upstream [#123](https://github.com/dollspace-gay/Thermite/issues/123): `remove` and iteration | NOT STARTED |
| T3 | irq / device / dma | no DMA target overlaps kernel memory | [G1](language-gaps.md#g1-map-needs-remove-and-iteration) / upstream [#123](https://github.com/dollspace-gay/Thermite/issues/123): `remove` | NOT STARTED |
| T4 | smp / sync / atomic | TLB shootdown correctness; lock safety | [G2](language-gaps.md#g2-no-concurrency-semantics), no concurrency semantics exist | NOT STARTED |

## The tiers now follow the locality test

The tiers below predate [the architecture pass](architecture.md) and were drawn
from the shape of the forked Rust models. Section 4 of the architecture applies
the invariant-locality test instead, and it moves two things:

- **T4's subsystems split.** Interrupt routing and timekeeping have local
  invariants and are admissible; the scheduler needs restructuring around an
  affine runnability grant before it is; message passing and device transfer
  isolation are OUT.
- **T0's subject changes.** It was a port of `context.rs`. The port is stopped:
  the upstream file is being withdrawn, and its nesting is what made it hit G4.
  The execution-context subsystem stays IN, designed fresh.

The tier table is kept because the blockers it records are still accurate. It
will be redrawn against the architecture's verdicts once a subsystem is actually
designed rather than listed.

## T0 is the whole near-term plan

T0 was described here as requiring no language work, on the basis that enums with
payloads, structs of fixed-width integers and booleans, and struct invariants are
all shipped in Thermite. They are, individually. Combining them is what fails: no
declared type may appear inside another, in any position
([G4](language-gaps.md#g4-struct-fields-of-user-declared-types)), and every
struct in the port has one.

That correction came from attempting the port rather than from re-reading the
survey, which is the general lesson. The claim "requires no language work" had
never been executed.

**The port is stopped.** `context.rs` is being withdrawn upstream, so porting it
means porting code that will not exist, and its nesting is a consequence of being
written for a language with a compositional type system. The execution-context
subsystem remains admissible under the locality test and will be designed rather
than ported.

Doing T0 first and completely still matters, because it is the first claim this
project will have made. What it proves is small; that it is proven, with a
certificate stating what it covers, is the point. G4 is a small upstream fix and
does not change that ordering.

## Ordering rationale

Every tier is gated on one small upstream fix,
[G4](language-gaps.md#g4-struct-fields-of-user-declared-types), because 11 of the
19 model files declare a struct with a user-declared field type and none of them
certify today. After G4: T0 and T1 are gated on effort, T2 and T3 additionally on
[G1](language-gaps.md#g1-map-needs-remove-and-iteration), and T4 on both G1 and
research.

G4 is therefore the critical path, and it is the smallest of the three.

G1 is two `Map` operations rather than a missing capability: `remove`, which
revocation and frame-free need, and iteration, which the schedulers and
allocators need to traverse. Both belong upstream in Thermite. The audit that
established this also cleared T1, whose only uncovered operation is `get_mut`,
which is `get` followed by `insert` in a value-semantics language.

## T4 is the gate on ambition

If [G2](language-gaps.md#g2-no-concurrency-semantics) gets an answer, monolithic
scope becomes arguable: more subsystems can live inside the verified core, and a
large kernel with a per-clause manifest is on the table. If it does not, the
separation-kernel shape is the maximum this approach reaches.

Either outcome is publishable. Neither should be claimed before it happens.

## Later: boot on physical hardware

`telos/it-actually-boots` names physical hardware as well as emulation, and
nothing has left QEMU. This is a goal for after the verified core has more in it,
recorded now so the analysis is not redone.

**What it would prove.** OVMF is not a vendor BIOS. Real firmware differs in the
memory map, MP Services and ACPI tables, and that handoff is the one thing QEMU
cannot report on. It is the only untested part of the boot path.

**What it would not prove.** Most of the acceptance matrix does not survive the
move. Hardware gives the CPU count the board has rather than 1/2/4/8, and the
AP-start-failure scenario is injected through `-fw_cfg opt/thermite/fail-ap`,
which has no hardware equivalent. Six scenarios become roughly two.

**Two constraints worth knowing before scoping it:**

- The runtime drives COM1 at I/O port `0x3f8` directly
  (`platform/x86_64-pc-uefi-smp-v1/runtime/src/main.rs:36`), so the board needs a
  real 16550 there — a UART header, or a BMC with serial-over-LAN. A USB-serial
  adapter on the board's own side cannot work, since nothing enumerates USB
  before the transcript starts.
- GitHub-hosted runners are VMs, so CI participation needs a self-hosted runner
  driving the board: storage the runner can write and then hand over, switched
  power for a cold boot per run, and serial captured on the runner's side.
  Labgrid and LAVA exist for this and would save writing the orchestration.

**What is already done.** `validate_transcript` in `test-qemu.py` is a standalone
function taking a list of `THERMITE_*` lines. The definition of a passing boot is
already hardware-agnostic; only the transport would change.

**The cheap first step**, whenever this is picked up: write the published image to
a USB stick, boot one machine by hand, capture the serial output, and feed it to
`validate_transcript`. That answers whether it boots on metal at all, with no
infrastructure, and tells you which board to build a rig around. Building the rig
before knowing that would be premature.

**The tension this trades against.** Every board the claim covers is firmware the
claim depends on, which is
`it-actually-boots` against `readable-trusted-base`, already recorded as a
tension. Hardware support enlarges the trusted base, and the enlargement is not
enumerable the way the registry is.

## Publishing the image: done

The image build is host-deterministic on a bare host: `SOURCE_DATE_EPOCH` pinned,
fixed volume ID, and two independent rebuilds compared byte-for-byte here rather
than taken on the profile's word. Checking it that way turned up a limit the
profile never claimed to cover, since the digests differ between hosts. Pinning
the toolchain by digest closes that: through `make image-container`, macOS/arm64
and ubuntu-24.04/x86-64 produce the same image ([evidence](reproduction.md)).
Upstream CI built the image, booted it, and discarded it.

It is now published: `upload-artifact` on every run, and an OCI push to
`ghcr.io/bulla-systems/bulla` on tags. [`docs/running.md`](running.md) makes it
runnable under `qemu-system-x86_64` without a Thermite installation. Evidence is
in [`docs/reproduction.md`](reproduction.md).

This required no verification work and produced none. It makes the project
legible to an outsider. T0 is next.
