# Reproduction record

What was run, on what, and what came out. This records a **reproduction of the
upstream baseline**, not a new result. No verification was added: the image's
proof content is the single exported function it had upstream.

Date: 2026-08-02. Upstream pin: `84d276e76ed02509ea58812efc15861d58580a42`.

## Host

| | |
|---|---|
| machine | Darwin 25.5.0, arm64 (Apple silicon) |
| rustc | 1.95.0, with `x86_64-unknown-uefi` |
| Verus | 0.2026.05.24.ecee80a (`arm64-macos`) |
| QEMU | 11.0.3 (Homebrew), TCG emulating x86-64 on arm64 |
| firmware | `edk2-x86_64-code.fd` + `edk2-i386-vars.fd` from Homebrew QEMU |
| image tools | dosfstools, mtools, LLVM 22.1.8, GNU coreutils |
| Python | 3.12.13 |

This is not the CI host. CI runs `ubuntu-latest` on x86-64. The results below are
from the macOS/arm64 host; CI results will appear on the workflow run.

## Results

Run on two hosts. Both are green; they do **not** produce the same image.

| step | macOS / arm64 | CI: ubuntu-24.04 / x86-64 |
|---|---|---|
| `make check-fork` | **pass** — 34 files, 33 byte-identical to the pin, 1 declared divergence | **pass** |
| `forge build --target kernel-image` | **pass** — 67108864 bytes | **pass** |
| `forge verify-build --json` | **pass** — `"valid": true` | **pass** |
| determinism, two builds compared | **pass** — byte-identical | **pass** — byte-identical |
| QEMU matrix, 6 scenarios | **pass** — all 6 | **pass** — all 6 |
| `docs/running.md` followed end to end | **pass** — booted from a clean directory | not run there |

CI run: [30779676660](https://github.com/bulla-systems/bulla/actions/runs/30779676660), 4m06s.

### The image, and the limit of the determinism claim

```
macOS / arm64        e08db880837bb0d2a90e7d23528aeefc116423f3240e8fd09dac0ae45313cac6
ubuntu-24.04 / x86-64  2ef4fdad0bef5c9b0bb88c1c5c651fb3b905be0f00364b4e36adda0fdeb33a2c
both                 67108864 bytes
```

**These differ, and that is the most important result on this page.** The
`deterministic_rebuilds = 2` claim in `profile.toml` holds *on a given host* —
two builds are byte-identical, twice over, on two different hosts. It does not
hold *across* hosts. Cross-compiling to `x86_64-unknown-uefi` from an
`aarch64-apple-darwin` toolchain and from an `x86_64-unknown-linux-gnu` toolchain
produces different PE bytes, even at the same pinned Rust channel, the same
`SOURCE_DATE_EPOCH`, and the same volume ID.

So the honest statement is: **the build is host-deterministic, not
reproducible.** Anyone re-deriving a published image must match the build host,
not just the source and the pin. Nothing upstream claimed otherwise — the profile
says `deterministic_rebuilds`, not "reproducible" — but the distinction is easy
to read past, and `docs/architecture.md` did read past it before this pass.

Both digests are stable: on each host, two independent builds from a clean
checkout of the pin, a fresh overlay, and a fresh `forge` produced the same
bytes. Within the macOS host, an image built from Bulla's forked tree and one
built from the **unmodified pin** also match — the one declared divergence is in
`test-qemu.py`, which is not an input to the image.

Narrowing this gap is real work and is not part of this pass. The likely levers
are `--remap-path-prefix`, a pinned linker, and a container-fixed toolchain.

### Determinism

`profile.toml` claims `deterministic_rebuilds = 2`, and forge's own receipt sets
`reproducible_pair_checked: true`. Both were confirmed from outside rather than
read back, because a receipt asserting that an image is reproducible is not
evidence that it is. Two full builds per host — each from a clean checkout of the
pin, a fresh overlay, and a fresh `forge`:

```
macOS / arm64          build 1: e08db880837bb0d2a90e7d23528aeefc116423f3240e8fd09dac0ae45313cac6
                       build 2: e08db880837bb0d2a90e7d23528aeefc116423f3240e8fd09dac0ae45313cac6
ubuntu-24.04 / x86-64  build 1: 2ef4fdad0bef5c9b0bb88c1c5c651fb3b905be0f00364b4e36adda0fdeb33a2c
                       build 2: 2ef4fdad0bef5c9b0bb88c1c5c651fb3b905be0f00364b4e36adda0fdeb33a2c
```

Identical within each host, different between them. See above.

### QEMU/OVMF acceptance matrix

All six scenarios passed, ending in `THERMITE_SUCCESS gate=boot-smp-v1`, with
`THERMITE_QEMU_MATRIX_SUCCESS cpus=1,2,4,8`. Per-scenario transcript digests as
bound into the receipt:

| CPUs | scenario | observed | transcript sha256 |
|---|---|---|---|
| 1 | nominal | `online=1 aps=0 work=2048` | `4c629976a150789000e2f5d2dea232e26f3f42dde3663e56497857a1e2f15d00` |
| 2 | nominal | `online=2 aps=1 work=4096` | `d9738cd1753790525ae03c71d045799e1d493385da95bfbf950935fef7f8ae05` |
| 4 | nominal | `online=4 aps=3 work=8192` | `33132a1e9b805bab755c3d124cb549b7398dd69ca6d343c70628a3c6ebd25580` |
| 8 | nominal | `online=8 aps=7 work=16384` | `1855aa701dcef5b5dac477031d99dbb606bb7f7e445282898054256852fad3f9` |
| 4 | ap-start-failure | `apic_id=3 state=Failed reason=injected online=3` | `c85bcba13681e509738a1d5ed22a8238c6917a4936c1893c6c2211027c1b65dd` |
| 2 | reboot | `action=reboot terminal=1` | `7e1b5180c0b43d32f0698ebc16820877fef4c21c33f79b6b001158539b59c4b5` |

No scenario was skipped, and none failed.

### What `verify-build` actually checked

```json
{
  "schema": "ThermiteBootableKernelValidationV1",
  "profile": "x86_64-pc-uefi-smp-v1",
  "image_sha256": "e08db880837bb0d2a90e7d23528aeefc116423f3240e8fd09dac0ae45313cac6",
  "binding_sha256": "4c3f8201b447b97542e25ba7a6b1f2e144f6f53d48fc80a6498521d8c6309fa1",
  "boot_profiles": [1, 2, 4, 8],
  "boot_scenarios": ["nominal", "nominal", "nominal", "nominal", "ap-start-failure", "reboot"],
  "replayed": false,
  "valid": true
}
```

Note `"replayed": false`. Without `--replay`, `verify-build` re-checks the
receipt's bindings and re-derives the proof evidence from current source; it does
**not** rebuild the image or re-boot it. The reproducibility result above comes
from `make determinism`, which is a separate thing. `docs/architecture.md`
previously ran those two together; it has been corrected.

## Assurance carried

Unchanged from upstream, stated as tuples per
[the assurance model](assurance-model.md):

```
kernel_step: result > 0    all / incomplete / solver @ to_platform(x86_64-pc-uefi-smp-v1)
```

One clause, on one exported function, whose implementation is a boundary call to
`tpl_clock_read`. `to_platform` because the body is a frozen registry entry.
`solver` because Verus discharged it and nothing re-checked the solver.

Everything else in the image — scheduler, allocator, frame lifecycle, capability
ledger, IRQ, DMA, SMP — is hand-written Rust with `none / none / fiat` and no
proof obligation at all. The boot transcript's `THERMITE_MODEL` line reports
those models *executing*, which is a test, not a proof.

**This pass added no verification.** T0 in [the roadmap](roadmap.md) is where
that starts, and it is NOT STARTED.

## Problems found, and what was done about them

### 1. forge's kernel-image target only works from its own workspace

`forge build --target kernel-image` resolves the platform profile directory
*and* its relative output path against forge's compile-time workspace root
(`env!("CARGO_MANIFEST_DIR")/..`). There is no `--profile-root`, and the
`--platform` flag only selects a name, which is then checked against a compiled-in
constant.

Checked twice, both decisive:

- With Bulla's `platform/` directory renamed away entirely, the documented build
  command still got past profile resolution and failed only on a missing host
  tool — it was reading the *other* checkout's copy.
- Invoked from Bulla with `--out dist/bulla.img`, it wrote the image, the EFI
  binary, the PDB and the receipt into `<thermite-clone>/dist/` and then failed
  reading them back from Bulla's `dist/`.

So a fork of the platform layer is not the thing that gets built unless it is
placed inside the pinned checkout. `scripts/build-image.sh` does that in a
scratch clone. **This is a workaround for a missing upstream flag, not a design**,
and the clean fix — a `--profile-root` option — belongs upstream in Thermite.

### 2. The acceptance harness cannot find firmware outside three Linux paths

`test-qemu.py` searched only `/usr/share/edk2/ovmf`, `/usr/share/OVMF`, and
`/usr/share/qemu`. On macOS all three are under SIP and cannot even be created,
so the gate could not run at all regardless of whether QEMU and OVMF were
installed. Arch Linux's `/usr/share/edk2/x64/` is also outside the list.

Bulla's copy adds a `BULLA_OVMF_DIR` root ahead of the three. That is the fork's
one declared divergence. It changes firmware *discovery* and nothing else — the
pairs, the QEMU command line, and every transcript assertion are untouched, so a
gate that passes here passes upstream. Worth upstreaming.

### 3. The harness needs Python 3.10+, undeclared

`test-qemu.py` calls `Path.write_text(..., newline=...)`, added in Python 3.10.
Under macOS's system Python 3.9 the first scenario boots successfully and then
dies with `TypeError: write_text() got an unexpected keyword argument 'newline'`
while writing its log — a passing boot reported as a failure. `ubuntu-latest` has
3.12, so upstream CI never sees it. Recorded in `docs/running.md`.

### 4. `registry.toml` points at a path this repository does not have

The forked `registry.toml` says `registry_source = "thermite-kernel/src/registry.rs"`.
Here that file is `kernel/src/registry.rs`. It is left as-is deliberately: the
string is correct at build time, because `scripts/build-image.sh` overlays
`kernel/` back onto `thermite-kernel/` in the clone, and editing it would add a
second divergence for no gain. Noted rather than changed.
