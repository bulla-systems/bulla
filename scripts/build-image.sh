#!/usr/bin/env bash
# Build the Bulla kernel image from this repository's forked platform tree,
# using `forge` from the upstream Thermite pin recorded in docs/upstream-pin.md.
#
# Why this script exists rather than a bare `forge build`:
#
#   `forge build --target kernel-image` resolves the platform profile directory
#   and its relative output path against forge's own compile-time workspace root
#   (`env!("CARGO_MANIFEST_DIR")/..` in forge/src/kernel_image.rs), rather than
#   from the current directory or a flag. There is no --profile-root. Run from
#   anywhere else, it reads another tree's platform/ and writes the image into
#   another tree's dist/. It works with the working directory set to the checkout
#   forge was compiled in, which is what upstream CI does.
#
# So: clone the pin into a scratch directory, overlay this repository's forked
# tree onto it, build forge there, run forge there, and copy the artifacts back.
# This is a workaround for a missing upstream flag.
#
# This script never touches any existing Thermite working copy.
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"

# The pin. Keep in step with docs/upstream-pin.md.
THERMITE_PIN=${THERMITE_PIN:-84d276e76ed02509ea58812efc15861d58580a42}
THERMITE_REMOTE=${THERMITE_REMOTE:-https://github.com/dollspace-gay/Thermite.git}
BUILD_ROOT=${BULLA_BUILD_ROOT:-$repo_root/.build}
OUT=${1:-dist/bulla.img}
out_dir=$(cd "$(dirname "$repo_root/$OUT")" 2>/dev/null && pwd || (mkdir -p "$(dirname "$repo_root/$OUT")" && cd "$(dirname "$repo_root/$OUT")" && pwd))
out_base=$(basename "$OUT")
out_stem=${out_base%.img}

clone="$BUILD_ROOT/thermite"
mkdir -p "$BUILD_ROOT"

# `git clone` refuses a non-empty destination, and the destination can already be
# non-empty without being a repository: a CI cache restores $clone/target before
# this ever runs. Init-and-fetch works from either state.
if [[ ! -d "$clone/.git" ]]; then
    echo "==> initializing $clone at the pin"
    mkdir -p "$clone"
    git -C "$clone" init --quiet
fi
if ! git -C "$clone" remote get-url origin >/dev/null 2>&1; then
    git -C "$clone" remote add origin "$THERMITE_REMOTE"
else
    git -C "$clone" remote set-url origin "$THERMITE_REMOTE"
fi
git -C "$clone" fetch --quiet --tags origin "$THERMITE_PIN" 2>/dev/null \
    || git -C "$clone" fetch --quiet origin
git -C "$clone" checkout --quiet --force "$THERMITE_PIN"
git -C "$clone" clean --quiet -fdx -e target -e dist
echo "==> upstream pinned at $(git -C "$clone" rev-parse HEAD)"

# Overlay this repository's forked tree. While the fork is unmodified this is a
# no-op on content; once Bulla diverges it is what gets the divergence built.
echo "==> overlaying forked platform/, kernel/, and src/ onto the pinned clone"
rm -rf "$clone/platform/x86_64-pc-uefi-smp-v1"
mkdir -p "$clone/platform"
cp -R "$repo_root/platform/x86_64-pc-uefi-smp-v1" "$clone/platform/"
# kernel/ is this repo's name for upstream's thermite-kernel/. The crate name is
# unchanged (docs/upstream-pin.md), so it lands back under the name the pinned
# workspace and the runtime's path dependency expect.
rm -rf "$clone/thermite-kernel"
cp -R "$repo_root/kernel" "$clone/thermite-kernel"
rm -rf "$clone/src"
cp -R "$repo_root/src" "$clone/src"

# forge compiles the frozen operation registry in from kernel/src/registry.rs,
# so it must be rebuilt after the overlay, not cached across divergent kernels.
echo "==> building forge from the overlaid clone"
cargo build --quiet --release --manifest-path "$clone/Cargo.toml" -p forge

echo "==> forge build --target kernel-image"
rm -rf "$clone/dist"
(
    cd "$clone"
    ./target/release/forge build src/bootable_kernel.th \
        --level l3 \
        --target kernel-image \
        --platform x86_64-pc-uefi-smp-v1 \
        --compose-export kernel_step \
        --compose-shell platform/x86_64-pc-uefi-smp-v1/kernel_shell.rs \
        --out "dist/$out_base"
)

echo "==> copying artifacts back to $out_dir"
mkdir -p "$out_dir"
for ext in img efi pdb sections symbols receipt receipt.json; do
    if [[ -f "$clone/dist/$out_stem.$ext" ]]; then
        cp "$clone/dist/$out_stem.$ext" "$out_dir/$out_stem.$ext"
    fi
done
ls -l "$out_dir"
