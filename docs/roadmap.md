# Roadmap

Five tiers, each naming its blocker. A tier is SHIPPED when it is end-to-end
functional with a non-test consumer, tests, and verification evidence, and
NOT STARTED otherwise, with a concrete open prerequisite. There is no "in
progress" status, since that is where overclaiming lives.

| tier | subsystem | property worth proving | blocker | status |
|---|---|---|---|---|
| T0 | privilege / context | a context entered as User is never resumed with Kernel privilege; a stale generation is never resumable | [G4](language-gaps.md#g4-struct-fields-of-user-declared-types) / upstream [#122](https://github.com/dollspace-gay/Thermite/issues/122) | NOT STARTED |
| T1 | capability ledger | no capability escalation; generation-safe revocation | `Vec` only, if the ledger scans linearly | NOT STARTED |
| T2 | frame / memory | no physical frame is double-allocated | [G1](language-gaps.md#g1--map-lowering), `Map` lowering | NOT STARTED |
| T3 | irq / device / dma | no DMA target overlaps kernel memory | [G1](language-gaps.md#g1--map-lowering) | NOT STARTED |
| T4 | smp / sync / atomic | TLB shootdown correctness; lock safety | [G2](language-gaps.md#g2--no-concurrency-semantics), no concurrency semantics exist | NOT STARTED |

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

T0 is gated on one small upstream fix (G4). T1 is gated on effort. T2 and T3 are
gated on a single unfinished Thermite requirement. T4 is gated on research.

One language increment, G1, unblocks the subsystems behind T2 and T3. Finishing
`Map` lowering is plausibly higher-leverage for this project than any kernel
work, and it belongs upstream in Thermite.

## T4 is the gate on ambition

If [G2](language-gaps.md#g2--no-concurrency-semantics) gets an answer, monolithic
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
