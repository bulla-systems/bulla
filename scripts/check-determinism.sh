#!/usr/bin/env bash
# Build the image twice from a clean overlay and compare the two byte for byte.
#
# profile.toml claims `deterministic_rebuilds = 2`, and forge sets
# `reproducible_pair_checked` in its own receipt. This target checks the claim
# from outside rather than reading it back from the artifact that asserts it,
# since a receipt saying an image is reproducible is not evidence that it is.
#
# The result is host-scoped: two builds on one machine match, and two builds on
# different machines do not. See docs/reproduction.md.
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"

work=$(mktemp -d "${TMPDIR:-/tmp}/bulla-determinism.XXXXXX")
trap 'rm -rf -- "$work"' EXIT

echo "==> build 1 of 2"
./scripts/build-image.sh dist/bulla.img >/dev/null
cp dist/bulla.img "$work/build-1.img"

echo "==> build 2 of 2"
./scripts/build-image.sh dist/bulla.img >/dev/null
cp dist/bulla.img "$work/build-2.img"

# sha256sum on Linux, shasum on macOS.
if command -v sha256sum >/dev/null; then
    sha256() { sha256sum | cut -d' ' -f1; }
else
    sha256() { shasum -a 256 | cut -d' ' -f1; }
fi
one=$(sha256 <"$work/build-1.img")
two=$(sha256 <"$work/build-2.img")
echo "build 1: $one"
echo "build 2: $two"

if cmp -s "$work/build-1.img" "$work/build-2.img"; then
    echo "IDENTICAL: two independent builds produced the same 67108864 bytes"
else
    echo "DIFFER: the deterministic_rebuilds = 2 claim does not hold here" >&2
    cmp "$work/build-1.img" "$work/build-2.img" || true
    exit 1
fi
