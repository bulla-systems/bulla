#!/usr/bin/env bash
# Re-check a built image against its receipt.
#
# Like the build, `forge verify-build` resolves the platform profile from its own
# compile-time workspace root, so it runs inside the overlaid clone rather than
# here. See docs/upstream-pin.md.
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"

BUILD_ROOT=${BULLA_BUILD_ROOT:-$repo_root/.build}
clone="$BUILD_ROOT/thermite"
IMAGE=${1:-dist/bulla.img}
base=$(basename "$IMAGE")
stem=${base%.img}

if [[ ! -x "$clone/target/release/forge" ]]; then
    echo "no forge in $clone — run 'make image' first" >&2
    exit 2
fi

mkdir -p "$clone/dist"
for ext in img receipt.json; do
    cp "$repo_root/$(dirname "$IMAGE")/$stem.$ext" "$clone/dist/$stem.$ext"
done

cd "$clone"
./target/release/forge verify-build "dist/$base" --json
