# Products

## One kernel, two profiles — not two kernels

The natural framing is "a small version and a big version," and it is wrong.
The two shapes differ in **what sits inside the boundary**, not in how much of
the same thing you get. They share the verified core, the registry mechanism,
and the build pipeline.

So: one codebase, two build profiles.

> **Open decision.** This supersedes the earlier `x` / `x-lite` framing. If two
> genuinely separate repositories turn out to be warranted — different release
> cadence, different platform sets — that is a later split, and it should be
> made because the code demanded it rather than because the naming implied it.

## Profile: `separation`

**Shape.** The kernel isolates partitions. Each partition runs something else,
possibly an entire commodity OS. Drivers live outside the trusted core.

**Why it comes first.** This is seL4's actual commercial deployment mode —
avionics, defense, automotive — and it is useful *without* a userland. The
claim is narrow and checkable: partitions cannot observe or affect each other
except through explicitly configured channels.

**Verified core contents:** address spaces, capability ledger, partition
scheduling, IPC channels, interrupt routing.

**Target claim.**

```
isolation   all / complete / lean-checked @ to_platform(x86_64-pc-uefi-smp-v1)
```

## Profile: `monolithic`

**Shape.** More subsystems inside the verified core — filesystems, network
stack, drivers — with no IPC on the hot path.

**Why it is second.** It fights two structural constraints rather than one:

- **Invariant locality.** Per-function contracts compose only when invariants
  are local. Monolithic designs create cross-cutting ones — no two partitions
  share a writable page unless configured; the runqueue is consistent with
  per-task state; no lock-ordering cycle exists globally. Those need
  whole-system reasoning, where cost is superlinear.
- **Concurrency.** See [G2](language-gaps.md#g2--no-concurrency-semantics).
  Thermite has no concurrency semantics at all, and this profile is where that
  binds hardest.

**Why it is worth aiming at anyway.** The goal is *not* "verified Linux." It is
a kernel of monolithic scope with a **complete, honest, per-clause assurance
manifest** — where most clauses certify and the remainder are explicitly named,
with an inventory that cannot be faked.

That artifact does not exist today, and it is defensible at 20% done, at 60%,
and at 95% — which is precisely the property the prior work lacked. A claim
that degrades gracefully is worth more than one that requires completion to be
true.

## What decides whether `monolithic` is real

[G2](language-gaps.md#g2--no-concurrency-semantics).

If concurrency gets a real semantics in Thermite, monolithic scope becomes
arguable and the interesting subsystems come inside the core. If it does not,
`separation` is not a fallback — it is the honest maximum, and the project
should say so plainly rather than keep the larger goal on the roadmap as
decoration.

Either outcome is a publishable result. Neither should be claimed in advance.

## Non-goals

Recorded so they stay non-goals:

- A general-purpose distribution — userland, package manager, init system
- POSIX compatibility
- Multi-architecture support before one platform is genuinely finished
- Performance competitiveness with Linux on any axis
- Any claim of the form "verified OS" without a tuple behind it
