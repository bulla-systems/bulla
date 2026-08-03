#!/usr/bin/env bash
# Check every forked file against the upstream pin, byte for byte.
#
# The fork is a copy of Thermite at the pin. Anywhere it differs, the difference
# must be a deliberate, listed divergence — otherwise it is drift, and drift in
# the platform layer is drift in the trusted base. See docs/upstream-pin.md.
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

divergence_reason() {
    printf '%s\n' "$DIVERGENCES" | while IFS=$'\t' read -r path reason; do
        [[ "$path" == "$1" ]] && printf '%s' "$reason"
    done
}

mkdir -p "$BUILD_ROOT"
if [[ ! -d "$clone/.git" ]]; then
    git clone --quiet --no-checkout "$THERMITE_REMOTE" "$clone"
fi
git -C "$clone" fetch --quiet origin "$THERMITE_PIN" 2>/dev/null \
    || git -C "$clone" fetch --quiet origin

upstream_path() {
    case "$1" in
        kernel/*) echo "thermite-kernel/${1#kernel/}" ;;
        src/*)    echo "conformance/${1#src/}" ;;
        *)        echo "$1" ;;
    esac
}

status=0
declared_seen=""
while IFS= read -r file; do
    up=$(upstream_path "$file")
    here=$(shasum -a 256 <"$file" | cut -d' ' -f1)
    if ! there=$(git -C "$clone" show "$THERMITE_PIN:$up" 2>/dev/null | shasum -a 256 | cut -d' ' -f1); then
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
# difference that is not there, which is its own kind of inaccurate record.
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
    echo "fork matches Thermite $THERMITE_PIN, with $declared_count declared divergence(s)"
fi
exit $status
