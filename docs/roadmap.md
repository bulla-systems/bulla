# Roadmap

Five tiers, each naming its blocker. A tier is SHIPPED when it is end-to-end
functional with a non-test consumer, tests, and verification evidence, and
NOT STARTED otherwise, with a concrete open prerequisite. There is no "in
progress" status, since that is where overclaiming lives.

| tier | subsystem | property worth proving | blocker | status |
|---|---|---|---|---|
| T0 | privilege / context | privilege non-escalation and generation safety, plus no kernel address, canonical addresses and stack alignment at creation | [G4](language-gaps.md#g4-struct-fields-of-user-declared-types) / upstream [#122](https://github.com/dollspace-gay/Thermite/issues/122), and [G12](language-gaps.md#g12-the-mutation-equivalence-probe-supports-only-scalar-returns) | NOT STARTED |
| T1 | capability ledger | no capability escalation; generation-safe revocation | [G4](language-gaps.md#g4-struct-fields-of-user-declared-types) only; the G1 audit clears it | NOT STARTED |
| T2 | frame / memory | no physical frame is double-allocated | [G1](language-gaps.md#g1-map-needs-remove-and-iteration): `remove` and iteration | NOT STARTED |
| T3 | irq / device / dma | no DMA target overlaps kernel memory | [G1](language-gaps.md#g1-map-needs-remove-and-iteration): `remove` | NOT STARTED |
| T4 | smp / sync / atomic | TLB shootdown correctness; lock safety | [G2](language-gaps.md#g2-no-concurrency-semantics), no concurrency semantics exist | NOT STARTED |

## T0 is the whole near-term plan

T0 was described here as requiring no language work, on the basis that enums with
payloads, structs of fixed-width integers and booleans, and struct invariants are
all shipped in Thermite. They are, individually. Combining them is what fails: a
struct with a field of user-declared type does not certify
([G4](language-gaps.md#g4-struct-fields-of-user-declared-types)), and every
struct in the port has one.

That correction came from attempting the port rather than from re-reading the
survey, which is the general lesson. The claim "requires no language work" had
never been executed.

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
