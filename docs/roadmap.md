# Roadmap

Five tiers, each naming its blocker. A tier is SHIPPED when it is end-to-end
functional with a non-test consumer, tests, and verification evidence, and
NOT STARTED otherwise, with a concrete open prerequisite. There is no "in
progress" status, since that is where overclaiming lives.

| tier | subsystem | property worth proving | blocker | status |
|---|---|---|---|---|
| T0 | privilege / context | a context entered as User is never resumed with Kernel privilege; a stale generation is never resumable | none; buildable today | NOT STARTED |
| T1 | capability ledger | no capability escalation; generation-safe revocation | `Vec` only, if the ledger scans linearly | NOT STARTED |
| T2 | frame / memory | no physical frame is double-allocated | [G1](language-gaps.md#g1--map-lowering), `Map` lowering | NOT STARTED |
| T3 | irq / device / dma | no DMA target overlaps kernel memory | [G1](language-gaps.md#g1--map-lowering) | NOT STARTED |
| T4 | smp / sync / atomic | TLB shootdown correctness; lock safety | [G2](language-gaps.md#g2--no-concurrency-semantics), no concurrency semantics exist | NOT STARTED |

## T0 is the whole near-term plan

[The MWE](mwe-context.md) is T0, and it requires no language work. Everything it
needs is already shipped in Thermite: enums with payloads, structs of
fixed-width integers and booleans, and struct invariants.

Doing T0 first and completely matters because it is the first claim this project
will have made. What it proves is small; that it is proven, with a certificate
stating what it covers, is the point.

## Ordering rationale

T0 and T1 are gated only on effort. T2 and T3 are gated on a single unfinished
Thermite requirement. T4 is gated on research.

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

The image build is host-deterministic: `SOURCE_DATE_EPOCH` pinned, fixed volume
ID, and two independent rebuilds compared byte-for-byte here rather than taken on
the profile's word. Checking it that way turned up the limit, since the digests
differ between hosts ([evidence](reproduction.md)). Upstream CI built the image,
booted it, and discarded it.

It is now published: `upload-artifact` on every run, and an OCI push to
`ghcr.io/bulla-systems/bulla` on tags. [`docs/running.md`](running.md) makes it
runnable under `qemu-system-x86_64` without a Thermite installation. Evidence is
in [`docs/reproduction.md`](reproduction.md).

This required no verification work and produced none. It makes the project
legible to an outsider. T0 is next.
