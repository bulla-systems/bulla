#!/usr/bin/env bash
# Build the image inside the pinned container, so the result depends on the
# source and the pin rather than on which machine ran it.
#
# `make determinism` compares two builds on one host, which cannot catch
# cross-host divergence by construction — it was green on both hosts while they
# disagreed. This is the target that can: run it on two different machines and
# compare the digests.
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"

IMAGE_TAG=${BULLA_BUILDER_TAG:-bulla-builder:pinned}
ENGINE=${BULLA_CONTAINER_ENGINE:-docker}
OUT=${1:-dist/bulla.img}

if ! command -v "$ENGINE" >/dev/null; then
    echo "no container engine: '$ENGINE' is not on PATH" >&2
    echo "set BULLA_CONTAINER_ENGINE, or install docker/podman" >&2
    exit 2
fi

# linux/amd64 explicitly: on an arm64 host this runs under emulation, which is
# slow and is the point — the toolchain binary has to be the same one.
echo "==> building the builder image (linux/amd64)"
"$ENGINE" build --platform linux/amd64 -t "$IMAGE_TAG" -f Containerfile .

echo "==> building the kernel image inside it"
"$ENGINE" run --rm \
    --platform linux/amd64 \
    -v "$repo_root":/work \
    -e THERMITE_PIN \
    -e THERMITE_REMOTE \
    -e BULLA_BUILD_ROOT=/work/.build-container \
    "$IMAGE_TAG" \
    ./scripts/build-image.sh "$OUT"

echo
echo "==> built in container:"
sha256sum "$OUT" 2>/dev/null || shasum -a 256 "$OUT"
echo
echo "Compare this digest against the same target run on a different machine."
echo "Matching digests are the cross-host claim; two builds on one host are not."
