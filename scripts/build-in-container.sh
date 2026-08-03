#!/usr/bin/env bash
# Build the disk image inside the pinned container, so its bytes depend on the
# source and the pin rather than on which machine ran the build.
#
# `make determinism` compares two builds on one host, which cannot catch
# cross-host divergence by construction — it was green on both hosts while the
# hosts disagreed. This is the target that can: run it on two different machines
# and compare the digests.
#
# Scope: this runs the frozen platform image builder only, not `forge build`.
# The determinism question is about the image bytes, and the proof closure, the
# receipt and the QEMU gate do not contribute any. Running the acceptance matrix
# inside an emulated amd64 container would nest TCG inside TCG for no added
# evidence about byte-identity; the gate runs natively via `make boot-matrix`.
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"

IMAGE_TAG=${BULLA_BUILDER_TAG:-bulla-builder:pinned}
ENGINE=${BULLA_CONTAINER_ENGINE:-docker}
THERMITE_PIN=${THERMITE_PIN:-84d276e76ed02509ea58812efc15861d58580a42}
THERMITE_REMOTE=${THERMITE_REMOTE:-https://github.com/dollspace-gay/Thermite.git}
OUT=${1:-dist/bulla-container.img}

if ! command -v "$ENGINE" >/dev/null; then
    echo "no container engine: '$ENGINE' is not on PATH" >&2
    echo "set BULLA_CONTAINER_ENGINE, or install docker/podman" >&2
    exit 2
fi

echo "==> building the builder image (linux/amd64)"
"$ENGINE" build --platform linux/amd64 -t "$IMAGE_TAG" -f Containerfile .

mkdir -p "$(dirname "$OUT")"

# The overlay is the same one scripts/build-image.sh performs: this repository's
# forked platform/ and kernel/ placed where the pinned tree expects them.
echo "==> building the disk image inside it"
"$ENGINE" run --rm \
    --platform linux/amd64 \
    -v "$repo_root":/work \
    -w /work \
    -e THERMITE_PIN="$THERMITE_PIN" \
    -e THERMITE_REMOTE="$THERMITE_REMOTE" \
    -e SOURCE_DATE_EPOCH=1704067200 \
    -e TZ=UTC \
    "$IMAGE_TAG" \
    bash -euo pipefail -c '
        clone=/work/.build-container/thermite
        mkdir -p "$(dirname "$clone")"
        if [ ! -d "$clone/.git" ]; then mkdir -p "$clone"; git -C "$clone" init --quiet; fi
        git -C "$clone" remote get-url origin >/dev/null 2>&1 \
            || git -C "$clone" remote add origin "$THERMITE_REMOTE"
        git -C "$clone" remote set-url origin "$THERMITE_REMOTE"
        git -C "$clone" fetch --quiet --tags origin "$THERMITE_PIN" 2>/dev/null \
            || git -C "$clone" fetch --quiet origin
        git -C "$clone" checkout --quiet --force "$THERMITE_PIN"
        git -C "$clone" clean --quiet -fdx -e target
        rm -rf "$clone/platform/x86_64-pc-uefi-smp-v1" "$clone/thermite-kernel"
        mkdir -p "$clone/platform"
        cp -R /work/platform/x86_64-pc-uefi-smp-v1 "$clone/platform/"
        cp -R /work/kernel "$clone/thermite-kernel"
        cd "$clone"
        ./platform/x86_64-pc-uefi-smp-v1/build-image.sh /work/'"$OUT"'
    '

echo
echo "==> built in container:"
if command -v sha256sum >/dev/null; then sha256sum "$OUT"; else shasum -a 256 "$OUT"; fi
echo
echo "Compare this digest against the same target run on a different machine."
echo "Matching digests are the cross-host claim; two builds on one host are not."
