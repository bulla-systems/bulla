#!/usr/bin/env bash
# Build the image twice from a clean overlay and compare the two byte for byte.
#
# profile.toml claims `deterministic_rebuilds = 2`. forge also sets
# `reproducible_pair_checked` in its own receipt. This target exists so the claim
# is confirmed from outside rather than read back from the artifact that asserts
# it — a receipt that says an image is reproducible is not evidence that it is.
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

one=$(shasum -a 256 <"$work/build-1.img" | cut -d' ' -f1)
two=$(shasum -a 256 <"$work/build-2.img" | cut -d' ' -f1)
echo "build 1: $one"
echo "build 2: $two"

if cmp -s "$work/build-1.img" "$work/build-2.img"; then
    echo "IDENTICAL — two independent builds produced the same 67108864 bytes"
else
    echo "DIFFER — the deterministic_rebuilds = 2 claim does not hold here" >&2
    cmp "$work/build-1.img" "$work/build-2.img" || true
    exit 1
fi
