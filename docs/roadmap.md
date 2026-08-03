# Roadmap

Five tiers. Each names its blocker. A tier is `SHIPPED` only when it is
end-to-end functional with a non-test consumer, tests, and verification
evidence; otherwise it is `NOT STARTED` with a concrete open prerequisite.
There is no "in progress" status, because that status is where overclaiming
lives.

| tier | subsystem | property worth proving | blocker | status |
|---|---|---|---|---|
| **T0** | privilege / context | a context entered as User can never be resumed with Kernel privilege; a stale generation is never resumable | **none — buildable today** | NOT STARTED |
| **T1** | capability ledger | no capability escalation; generation-safe revocation | `Vec` only, if the ledger scans linearly | NOT STARTED |
| **T2** | frame / memory | **no physical frame is ever double-allocated** | [G1](language-gaps.md#g1--map-lowering) — `Map` lowering | NOT STARTED |
| **T3** | irq / device / dma | no DMA target overlaps kernel memory | [G1](language-gaps.md#g1--map-lowering) | NOT STARTED |
| **T4** | smp / sync / atomic | TLB shootdown correctness; lock safety | [G2](language-gaps.md#g2--no-concurrency-semantics) — no concurrency semantics exist | NOT STARTED |

## T0 is the whole near-term plan

[The MWE](mwe-context.md) is T0 and it requires **no language work**. Everything
it needs — enums with payloads, structs of fixed-width integers and booleans,
struct invariants — is already shipped in Thermite.

The reason to be strict about doing T0 first, and completely, is that it is the
first time this project will have made a real claim. What it proves is small.
That it is *actually proven*, with a certificate that says exactly what it
covers, is the entire point.

## Ordering rationale

T0 and T1 are gated only on effort. T2 and T3 are gated on a single unfinished
Thermite requirement. T4 is gated on research.

That distribution is worth reading carefully: **one language increment (G1)
unblocks roughly seven kernel subsystems.** Finishing `Map` lowering is
plausibly higher-leverage for this project than any kernel work, and it belongs
upstream in Thermite rather than here.

## T4 is the gate on ambition

If [G2](language-gaps.md#g2--no-concurrency-semantics) gets a real answer,
monolithic scope becomes arguable — more subsystems can live inside the verified
core, and the honest-manifest version of a large kernel is on the table. If it
does not, the separation-kernel shape is not a compromise; it is the honest
maximum.

Either outcome is publishable. Neither should be claimed before it happens.

## Free win — done

The image build is deterministic: `SOURCE_DATE_EPOCH` pinned, fixed volume ID,
and two independent rebuilds compared byte-for-byte here rather than taken on
the profile's word. Upstream CI built it, booted it, and threw it away.

It is now published — `upload-artifact` on every run, an OCI push to
`ghcr.io/bulla-systems/bulla` on tags — and
[`docs/running.md`](running.md) makes it `qemu-system-x86_64`-runnable by someone
with no Thermite installation. Evidence: [`docs/reproduction.md`](reproduction.md).

This required no verification work and produced none. It is what makes the
project legible to an outsider, and nothing more than that. **T0 is next.**
