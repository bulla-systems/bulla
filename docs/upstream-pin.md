# The upstream pin

Bulla consumes a toolchain rather than vendoring one, from a fixed upstream
commit. That commit is a trust-relevant input to every image this repository
produces, so it is recorded here instead of being left implicit in a lockfile.

## The pin

```
repository  https://github.com/dollspace-gay/Thermite
commit      84d276e76ed02509ea58812efc15861d58580a42
date        2026-08-01
subject     Build bootable multicore kernel (#114)
```

## Why this commit

Two reasons, both checkable.

1. It introduced the thing being reproduced. PR #114 added
   `forge --target kernel-image`, the `x86_64-pc-uefi-smp-v1` profile, and the CI
   job that builds and boots the image. Pinning earlier means the target does not
   exist; pinning later means reproducing a different artifact.

2. It is the commit this repository's documents were written against.
   `docs/language-gaps.md` states its baseline as Thermite `84d276e7`. If the pin
   moved without the documents moving, the docs would describe a tree the build
   no longer consumes.

The pin is on `origin/main` upstream, so it is fetchable by anyone rather than
only from a local checkout.

## What is pinned, and what is forked

| | source | in this repo |
|---|---|---|
| `forge` (compiler, prover driver, image builder) | pinned upstream | not copied; built from the pin |
| `platform/x86_64-pc-uefi-smp-v1/**` | upstream at the pin | forked to the same path |
| `thermite-kernel/**` | upstream at the pin | forked to `kernel/**` |
| `conformance/bootable_kernel.th` | upstream at the pin | forked to `src/bootable_kernel.th` |
| `conformance/kernel_primitives.th` | upstream at the pin | forked to `src/kernel_primitives.th` |

Every forked file except one is byte-identical to the pinned upstream. While the
fork stays that way, an image built here is bit-identical to one built upstream
on the same host, and any divergence shows up as a diff. `make check-fork`
re-checks byte-identity against the pin and requires every difference to be
declared with a reason.

## How the build reaches the pin

`forge` resolves the platform profile directory from its own compile-time
workspace root, `env!("CARGO_MANIFEST_DIR")/..` in `forge/src/kernel_image.rs`,
rather than from the current directory or a flag. There is no `--profile-root`. A
`forge` binary built from a Thermite checkout reads
`<thermite>/platform/x86_64-pc-uefi-smp-v1/` and ignores an identically named
directory in the repository it is invoked from.

This was checked. With Bulla's `platform/` directory renamed out of the way, the
documented `forge build` command still proceeds past profile resolution and fails
on a missing host tool. [docs/reproduction.md](reproduction.md) has the
transcript.

Bulla's forked `platform/` and `kernel/` trees are therefore not the build inputs
unless they are placed inside the pinned checkout. `scripts/build-image.sh` does
that in a scratch clone, and never touches any working copy of Thermite:

1. clone the upstream at the pin into `.build/thermite`, or fetch if present
2. copy `platform/` over `<clone>/platform/`, and `kernel/` over
   `<clone>/thermite-kernel/`
3. build `forge` from the overlaid clone. The frozen operation registry is Rust
   source in `kernel/src/registry.rs` compiled into `forge`, rather than read
   from `registry.toml` at run time, so a divergent kernel needs a rebuilt forge.
4. run that `forge` from inside the clone, since it resolves its output path the
   same way it resolves the profile directory, then copy the artifacts back

This is a workaround for a missing upstream flag. The fix is a `--profile-root`
option on `forge build --target kernel-image`, which belongs upstream in
Thermite. Until it exists, the overlay is what makes a fork of the platform layer
the thing that gets built.

## Moving the pin

Moving it changes the trusted base and is reviewed as such:

- update the commit above, with the reason it moved
- re-run `make check-fork`, and resolve every reported divergence either by
  taking upstream's version or by recording why Bulla's differs
- re-run the reproduction (`make image`, `make verify`, `make determinism`,
  `make boot-matrix`) and update `docs/reproduction.md` with the new results

## Licensing

Upstream is MIT, and `LICENSE` here carries both copyright lines. No forked file
carried a file-level copyright or SPDX notice upstream, checked at the pin across
all 34 forked files, so there were none to preserve. The repository-level notice
is the whole of the attribution, as it was upstream.

The `THERMITE_*` serial-protocol markers, the `THERMITE` FAT volume label, and
the `thermite-kernel` crate name are unchanged in the forked tree. They are part
of the frozen profile: `test-qemu.py` matches those strings literally, and the
volume label is an input to the image bytes. Renaming them would break the
acceptance harness and change the image digest, which would remove the baseline
this pass is measured against.
