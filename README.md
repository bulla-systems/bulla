# Bulla

A verified kernel whose trusted computing base is a list you can read in an
afternoon, carrying a machine-generated certificate for everything else.

Written in [Thermite](https://github.com/dollspace-gay/Thermite), a
verification-mandatory contract language.

---

## Status

A bootable image, reproduced from the upstream baseline and published. No
verified kernel code yet.

| | status |
|---|---|
| bootable image, built and booted here | SHIPPED. `dist/bulla.img`, six of six QEMU/OVMF scenarios on two hosts, byte-identical across two builds on each ([evidence](docs/reproduction.md)) |
| image published where an outsider can fetch and run it | SHIPPED. CI artifact and GHCR push ([how to run it](docs/running.md)) |
| T0, a verified kernel subsystem | NOT STARTED. Blocker: none; it is next, and requires no language work ([MWE](docs/mwe-context.md)) |

The published image proves that `kernel_step` returns a positive number. That is
one exported function whose body is a clock read through a boundary, which makes
it a link-integrity probe rather than a security property. The scheduler,
allocator, frame lifecycle, capability ledger, IRQ, DMA and SMP code in the image
is hand-written Rust and is unverified. The image carries the assurance the
upstream one carried; reproducing and publishing it added none.

The failure mode this project exists to avoid is describing architecture as
though it were achievement. Every claim in these documents is either shipped with
evidence or not started with its blocker named. There is no third category.

## What a bulla is

A *bulla* is a hollow clay ball from Mesopotamia, c. 4000 BCE, holding counting
tokens, with the token shapes impressed on its outside. To check the contents you
had to break the seal. It is the earliest known tamper-evident record, and
plausibly the origin of writing.

The name is the thesis: the manifest on the outside describes the contents
inside, and you cannot alter one without destroying the other.

## Scope

- **Not an operating system.** A kernel is one layer. There is no userland,
  package manager, init system, or distribution. Those would be separate and
  later claims.
- **Not a general-purpose kernel.** See [product shape](#product-shape).
- **Verification is partial by construction.** It is per-clause. The deliverable
  is knowing which parts are proven and which are not.

## The claim, compared

| | trusted computing base |
|---|---|
| Linux | ~30M lines of ring-0 C, unreadable in practice |
| seL4 | ~10k lines plus Isabelle proofs requiring expert maintenance |
| Bulla | a frozen operation registry plus its bound bodies, with a certificate for everything above it |

The differentiator is proof mechanism rather than proof volume: the boundary
between trusted and proven is enforced by the build. A privileged operation that
does not appear in the registry cannot be called.

## Product shape

Three shapes are possible for a verified kernel. One of them is an OS.

1. **Unikernel / appliance.** One workload linked with the kernel into a single
   bootable image. No dynamic loading, so no unverified code enters, and the
   whole image is one closure that can be certified end to end. This is the
   near-term target, and it has the strongest assurance story.
2. **Separation kernel.** The kernel isolates partitions; each runs something
   else. This is seL4's commercial deployment mode, and it is useful without a
   userland.
3. **General-purpose OS.** A full distribution. Not a target.

The path is (1) → (2). (3) is a direction rather than a destination.

## Documents

| | |
|---|---|
| [Architecture](docs/architecture.md) | the four layers, the boundary registry, and how a `.th` program becomes a bootable image |
| [Products](docs/products.md) | the `separation` and `monolithic` profiles, and what decides whether the second is real |
| [Assurance model](docs/assurance-model.md) | what a certificate claims, and the vocabulary for saying it |
| [Roadmap](docs/roadmap.md) | T0–T4, with the blocker for each tier named |
| [Language gaps](docs/language-gaps.md) | what Thermite cannot yet express, and what it would take |
| [MWE: the privilege state machine](docs/mwe-context.md) | the first buildable increment, in full |
| [Running the image](docs/running.md) | the `qemu-system-x86_64` invocation, and how to get OVMF |
| [Upstream pin](docs/upstream-pin.md) | which Thermite commit, why that one, and how the build reaches it |
| [Reproduction record](docs/reproduction.md) | what was run, on what, and what came out, including what did not work |
| [Tone and voice](docs/tone-and-voice.md) | the prose standard for this repository |
| [Contributing](CONTRIBUTING.md) | the CI-vs-authoring enforcement split, and claims discipline |

## Relationship to prior work

The platform layer, boundary registry, and bring-up code this project builds on
were written by [dollspace.gay](https://github.com/dollspace-gay) in the Thermite
repository: a fifteen-field boundary matcher, fail-closed registry policies,
sealed capability kinds, and a host-deterministic image build. That work is the
reason this project starts here rather than from scratch.

What it did not have was a verified payload. The kernel subsystems were modeled
in ordinary Rust rather than proven in Thermite, and the assurance table
described the architecture's capacity rather than its contents. Bulla forks the
scaffolding and builds the thing it was designed to carry.

## License

MIT. See [LICENSE](LICENSE); copyright is retained for the original platform
work.
