#!/usr/bin/env bash
# Check every forked file against the upstream pin, byte for byte.
#
# The fork is a copy of Thermite at the pin. Any difference must be a listed
# divergence with a reason; anything else is drift, and drift in the platform
# layer is drift in the trusted base. See docs/upstream-pin.md.
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
cd "$repo_root"

THERMITE_PIN=${THERMITE_PIN:-84d276e76ed02509ea58812efc15861d58580a42}
THERMITE_REMOTE=${THERMITE_REMOTE:-https://github.com/dollspace-gay/Thermite.git}
BUILD_ROOT=${BULLA_BUILD_ROOT:-$repo_root/.build}
clone="$BUILD_ROOT/thermite-ref"

# Declared divergences: paths expected to differ from the pin, each with the
# reason, as `path<TAB>reason`. Anything differing that is not listed here fails.
# A plain list rather than an associative array so this runs under bash 3.2,
# which is what /usr/bin/bash still is on macOS.
DIVERGENCES=$(cat <<'EOF'
platform/x86_64-pc-uefi-smp-v1/test-qemu.py	adds BULLA_OVMF_DIR as a firmware search root; discovery only, no change to any transcript assertion
EOF
)

# Always succeeds. The `[[ ]] && printf` compound returns 1 on a non-matching
# line, which as the loop body's last command makes the loop, and so the
# function, return 1 — and under `set -e` that killed the script at the first
# undeclared drift, before it could report anything. An exit-code-only negative
# test does not catch that, because the exit code is 1 either way.
divergence_reason() {
    printf '%s\n' "$DIVERGENCES" | while IFS=$'\t' read -r path reason; do
        if [[ "$path" == "$1" ]]; then printf '%s' "$reason"; fi
    done
    return 0
}

# sha256sum on Linux, shasum on macOS. Both print `<digest>  <name>`.
if command -v sha256sum >/dev/null; then
    sha256() { sha256sum | cut -d' ' -f1; }
else
    sha256() { shasum -a 256 | cut -d' ' -f1; }
fi

mkdir -p "$BUILD_ROOT"
# Init-and-fetch rather than clone: the destination may already exist without
# being a repository (see the same note in build-image.sh).
if [[ ! -d "$clone/.git" ]]; then
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

upstream_path() {
    case "$1" in
        kernel/*) echo "thermite-kernel/${1#kernel/}" ;;
        src/*)    echo "conformance/${1#src/}" ;;
        *)        echo "$1" ;;
    esac
}

status=0
authored=0
declared_seen=""
while IFS= read -r file; do
    up=$(upstream_path "$file")
    here=$(sha256 <"$file")
    if ! there=$(git -C "$clone" show "$THERMITE_PIN:$up" 2>/dev/null | sha256); then
        # platform/ and kernel/ are wholesale forks: a file with no upstream
        # counterpart there is drift. src/ is this repository's own source
        # directory that happens to contain two forked .th files, so a file
        # with no counterpart there is Bulla-authored, which is the point.
        if [[ "$file" == src/* ]]; then
            echo "AUTHORED $file (not forked; no upstream counterpart expected)"
            authored=$((authored + 1))
            continue
        fi
        echo "ADDED    $file (no counterpart at $up upstream)"
        status=1
        continue
    fi
    if [[ "$here" == "$there" ]]; then
        continue
    fi
    reason=$(divergence_reason "$file")
    if [[ -n "$reason" ]]; then
        echo "DIVERGES $file"
        echo "         reason: $reason"
        declared_seen="$declared_seen$file"$'\n'
    else
        echo "DRIFT    $file differs from $up at the pin, and is not a declared divergence"
        status=1
    fi
done < <(find platform kernel src -type f | sort)

# A divergence that no longer diverges is stale bookkeeping: the entry claims a
# difference that is not present.
declared_count=0
while IFS=$'\t' read -r path _; do
    [[ -z "$path" ]] && continue
    declared_count=$((declared_count + 1))
    if ! printf '%s' "$declared_seen" | grep -qxF "$path"; then
        echo "STALE    $path is declared as a divergence but matches the pin"
        status=1
    fi
done <<< "$DIVERGENCES"

if [[ $status -eq 0 ]]; then
    echo "fork matches Thermite $THERMITE_PIN, with $declared_count declared divergence(s) and $authored Bulla-authored file(s)"
fi
exit $status
