# The upstream pin

Bulla does not vendor a toolchain. It consumes one, from a fixed upstream
commit. That commit is a trust-relevant input to every image this repository
produces, so it is recorded here rather than left implicit in a lockfile.

## The pin

```
repository  https://github.com/dollspace-gay/Thermite
commit      84d276e76ed02509ea58812efc15861d58580a42
date        2026-08-01
subject     Build bootable multicore kernel (#114)
```

## Why this commit

Two reasons, both checkable:

1. **It is the commit that introduced the thing being reproduced.** PR #114 is
   what added `forge --target kernel-image`, the `x86_64-pc-uefi-smp-v1`
   profile, and the CI job that builds and boots the image. Pinning earlier
   means the target does not exist; pinning later means reproducing something
   other than the artifact this pass set out to reproduce.

2. **It is the commit this repository's documents were written against.**
   `docs/language-gaps.md` states its baseline as Thermite `84d276e7`. If the
   pin moved without the documents moving, the docs would describe a tree the
   build no longer consumes.

The pin is on `origin/main` of the upstream repository, so it is fetchable by
anyone, not just from a local checkout.

## What is pinned, and what is forked

| | source | in this repo |
|---|---|---|
| `forge` (compiler, prover driver, image builder) | pinned upstream | **not copied** — built from the pin |
| `platform/x86_64-pc-uefi-smp-v1/**` | upstream at the pin | forked to the same path |
| `thermite-kernel/**` | upstream at the pin | forked to `kernel/**` |
| `conformance/bootable_kernel.th` | upstream at the pin | forked to `src/bootable_kernel.th` |
| `conformance/kernel_primitives.th` | upstream at the pin | forked to `src/kernel_primitives.th` |

Every forked file is currently **byte-identical** to the pinned upstream. That
is deliberate: while the fork is unmodified, an image built here is bit-identical
to one built upstream, and any divergence is a diff rather than an argument.
`make check-fork` re-checks byte-identity against the pin and is the mechanical
form of that claim.

## How the build reaches the pin

`forge` resolves the platform profile directory from **its own compile-time
workspace root** — `env!("CARGO_MANIFEST_DIR")/..` in
`forge/src/kernel_image.rs` — not from the current directory and not from any
flag. There is no `--profile-root`. A `forge` binary built from a Thermite
checkout will therefore read `<thermite>/platform/x86_64-pc-uefi-smp-v1/`, and
will ignore an identically-named directory in the repository it is invoked from.

This is not a guess; it is checked. With Bulla's `platform/` directory renamed
out of the way entirely, the documented `forge build` command still proceeds
past profile resolution and fails only on a missing host tool. See
[docs/reproduction.md](reproduction.md) for the transcript.

The consequence: **Bulla's forked `platform/` and `kernel/` trees are not the
build inputs unless they are placed inside the pinned checkout.**
`scripts/build-image.sh` does exactly that, in a scratch clone, and never
touches any working copy of Thermite:

1. clone the upstream at the pin into `.build/thermite` (or fetch, if present)
2. copy `platform/` over `<clone>/platform/`, and `kernel/` over
   `<clone>/thermite-kernel/`
3. build `forge` from the overlaid clone — necessary because the frozen
   operation registry is Rust source in `kernel/src/registry.rs` that is
   compiled *into* `forge`, not read from `registry.toml` at run time
4. invoke that `forge` with the working directory set to this repository, so
   the `.th` sources and the composition shell resolve here

Steps 1–3 are a workaround for a missing upstream flag, not a design. The clean
version is a `--profile-root` option on `forge build --target kernel-image`,
which belongs upstream in Thermite. Until that exists, the overlay is the only
mechanism by which a fork of the platform layer is actually the thing that gets
built.

## Moving the pin

Moving it is a change to the trusted base and is reviewed as one:

- update the commit above, with the reason it moved
- re-run `make check-fork`; resolve every reported divergence explicitly, either
  by taking upstream's version or by recording why Bulla's differs
- re-run the full reproduction (`make image`, `make verify`, `make determinism`,
  `make boot-matrix`) and update `docs/reproduction.md` with the new results

## Licensing

Upstream is MIT. `LICENSE` here carries both copyright lines. No forked file
carried a file-level copyright or SPDX notice upstream — checked at the pin
across all 34 forked files — so there were none to preserve; the repository-level
notice is the whole of the attribution, as it was upstream.

The `THERMITE_*` serial-protocol markers, the `THERMITE` FAT volume label, and
the `thermite-kernel` crate name are **left unchanged** in the forked tree. They
are part of the frozen profile: `test-qemu.py` matches those exact strings, and
the volume label is an input to the deterministic image bytes. Renaming them
would break the acceptance harness and change the image digest, which would
defeat the point of reproducing the baseline before diverging from it.
