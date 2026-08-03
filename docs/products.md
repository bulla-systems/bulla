# Products

## One kernel, two profiles

The natural framing is "a small version and a big version," and it misleads. The
two shapes differ in what sits inside the boundary, and share the verified core,
the registry mechanism, and the build pipeline.

One codebase, two build profiles.

> **Open decision.** This supersedes the earlier `x` / `x-lite` framing. If two
> separate repositories turn out to be warranted, for a different release cadence
> or different platform sets, that is a later split, made because the code
> required it rather than because the naming implied it.

## Profile: `separation`

**Shape.** The kernel isolates partitions. Each partition runs something else,
possibly an entire commodity OS. Drivers live outside the trusted core.

**Why it comes first.** This is seL4's commercial deployment mode, in avionics,
defense and automotive, and it is useful without a userland. The claim is narrow
and checkable: partitions cannot observe or affect each other except through
configured channels.

**Verified core contents:** address spaces, capability ledger, partition
scheduling, IPC channels, interrupt routing.

**Target claim.**

```
isolation   all / complete / lean-checked @ to_platform(x86_64-pc-uefi-smp-v1)
```

## Profile: `monolithic`

**Shape.** More subsystems inside the verified core, including filesystems, the
network stack and drivers, with no IPC on the hot path.

**Why it is second.** It meets two structural constraints rather than one:

- **Invariant locality.** Per-function contracts compose when invariants are
  local. Monolithic designs create cross-cutting ones: no two partitions share a
  writable page unless configured, the runqueue is consistent with per-task
  state, no lock-ordering cycle exists globally. Those need whole-system
  reasoning, where cost is superlinear.
- **Concurrency.** See [G2](language-gaps.md#g2-no-concurrency-semantics).
  Thermite has no concurrency semantics at all, and this profile is where that
  binds hardest.

**Why it is worth aiming at anyway.** The goal is a kernel of monolithic scope
with a complete per-clause assurance manifest, where most clauses certify and the
remainder are named, backed by an inventory that cannot be faked. It is not
"verified Linux".

That artifact does not exist today, and it holds up at 20% done, at 60%, and at
95%, which is the property the prior work lacked. A claim that degrades
gracefully is worth more than one that requires completion to be true.

## What decides whether `monolithic` is real

[G2](language-gaps.md#g2-no-concurrency-semantics).

If concurrency gets a semantics in Thermite, monolithic scope becomes arguable
and the interesting subsystems come inside the core. If it does not, `separation`
is the maximum this approach reaches, and the project should say so rather than
keep the larger goal on the roadmap as decoration.

Either outcome is a publishable result. Neither should be claimed in advance.

## Non-goals

Recorded so they stay non-goals:

- A general-purpose distribution: userland, package manager, init system
- POSIX compatibility
- Multi-architecture support before one platform is finished
- Performance competitiveness with Linux on any axis
- Any claim of the form "verified OS" without a tuple behind it
