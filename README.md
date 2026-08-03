# Bulla

A verified kernel whose **trusted computing base is a list you can read in an
afternoon**, and which carries a machine-generated certificate for everything
else.

Written in [Thermite](https://github.com/dollspace-gay/Thermite), a
verification-mandatory contract language.

---

## Status: an image that boots, carrying nothing proven

There is now a bootable image here, reproduced from the upstream baseline and
published. There is still **no verified kernel code**. Those are two different
statements and the difference is the entire project.

| | status |
|---|---|
| bootable image, built and booted here | **SHIPPED** — `dist/bulla.img`, six of six QEMU/OVMF scenarios on two hosts, byte-identical across two builds on each ([evidence](docs/reproduction.md)) |
| image published where an outsider can fetch and run it | **SHIPPED** — CI artifact and GHCR push ([how to run it](docs/running.md)) |
| T0 — a verified kernel subsystem | **NOT STARTED** — blocker: none. It is next, and no language work is required ([MWE](docs/mwe-context.md)) |

**The published image proves one thing: that `kernel_step` returns a positive
number.** That is a single exported function whose body is a clock read through
a boundary — a link-integrity probe, not a security property. Every subsystem in
the image (scheduler, allocator, frame lifecycle, capability ledger, IRQ, DMA,
SMP) is hand-written Rust and is **not verified**. The image carries exactly the
assurance the upstream one did; reproducing and publishing it added none.

This is stated plainly because the failure mode this project exists to avoid is
describing architecture as though it were achievement. Every claim in these
documents is either marked as shipped with evidence, or marked as not started
with its blocker named. There is no third category.

## What a bulla is

A *bulla* is a hollow clay ball from Mesopotamia, c. 4000 BCE, holding counting
tokens, with the token shapes impressed on its outside. To check the contents
you had to break the seal. It is the earliest known tamper-evident record — and
plausibly the origin of writing.

The name is the thesis: **the manifest on the outside must describe the contents
inside, and you cannot alter one without destroying the other.**

## What this is not

- **Not an operating system.** A kernel is one layer. There is no userland, no
  package manager, no init system, no distribution. If those are ever built,
  they are a separate and later claim.
- **Not a general-purpose kernel.** See [product shape](#product-shape).
- **Not a claim that verification is finished.** Verification is per-clause and
  partial by construction. The deliverable is knowing *exactly* which parts are
  proven and which are not.

## The claim, compared

| | trusted computing base |
|---|---|
| Linux | ~30M lines of ring-0 C, unreadable in practice |
| seL4 | ~10k lines plus Isabelle proofs requiring expert maintenance |
| **Bulla** | a frozen operation registry plus its bound bodies — with a certificate for everything above it |

The differentiator is not proof volume. It is that the boundary between trusted
and proven is **mechanically enforced** rather than documented: a privileged
operation that does not appear in the registry cannot be called at all.

## Product shape

Three shapes are possible for a verified kernel. Only one of them is an OS.

1. **Unikernel / appliance** — one workload linked with the kernel into a single
   bootable image. No dynamic loading, so no unverified code ever enters, and
   the whole image is one closure you can certify end to end. **Strongest
   assurance story. This is the near-term target.**
2. **Separation kernel** — the kernel isolates partitions; each runs something
   else. This is seL4's actual commercial deployment mode, and it is useful
   without a userland.
3. **General-purpose OS** — a full distribution. Not a target.

The path is (1) → (2). (3) is a direction, not a destination.

## Documents

| | |
|---|---|
| [Architecture](docs/architecture.md) | the four layers, the boundary registry, and how a `.th` program becomes a bootable image |
| [Products](docs/products.md) | the two profiles — `separation` and `monolithic` — and what decides whether the second is real |
| [Assurance model](docs/assurance-model.md) | what a certificate claims, and the vocabulary for saying it precisely |
| [Roadmap](docs/roadmap.md) | T0–T4, with the blocker for each tier named |
| [Language gaps](docs/language-gaps.md) | what Thermite cannot yet express, and what it would take |
| [MWE: the privilege state machine](docs/mwe-context.md) | the first buildable increment, in full |
| [Running the image](docs/running.md) | the exact `qemu-system-x86_64` invocation, and how to get OVMF |
| [Upstream pin](docs/upstream-pin.md) | which Thermite commit, why that one, and how the build reaches it |
| [Reproduction record](docs/reproduction.md) | what was run, on what, and what came out — including what did not work |
| [Contributing](CONTRIBUTING.md) | the CI-vs-authoring enforcement split, and claims discipline |

## Relationship to prior work

The platform layer, boundary registry, and bring-up code this project builds on
were written by [dollspace.gay](https://github.com/dollspace-gay) in the
Thermite repository — a genuinely good architecture: a fifteen-field boundary
matcher, fail-closed registry policies, sealed capability kinds, and a
deterministic reproducible image build. That work is the reason this project is
worth starting rather than beginning from scratch.

What it did not have was a verified payload: the kernel subsystems were modeled
in ordinary Rust rather than proven in Thermite, and the assurance table
described the architecture's capacity rather than its contents. Bulla forks the
scaffolding and builds the thing it was designed to carry.

## License

MIT. See [LICENSE](LICENSE) — copyright is retained for the original platform
work.
