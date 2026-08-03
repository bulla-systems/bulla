# Reproduction record

What was run, on what, and what came out. This records a reproduction of the
upstream baseline. No verification was added: the image's proof content is the
single exported function it had upstream.

Date: 2026-08-02. Upstream pin: `84d276e76ed02509ea58812efc15861d58580a42`.

## Hosts

| | development host | CI |
|---|---|---|
| machine | Darwin 25.5.0, arm64 | ubuntu-24.04, x86-64 |
| rustc | 1.95.0, with `x86_64-unknown-uefi` | 1.95.0, with `x86_64-unknown-uefi` |
| Verus | 0.2026.05.24.ecee80a (`arm64-macos`) | 0.2026.05.24.ecee80a (`x86-linux`) |
| QEMU | 11.0.3 (Homebrew), TCG emulating x86-64 on arm64 | distribution QEMU, TCG |
| firmware | `edk2-x86_64-code.fd` + `edk2-i386-vars.fd` from Homebrew QEMU | `OVMF_CODE_4M.fd` + `OVMF_VARS_4M.fd` |
| image tools | dosfstools, mtools, LLVM 22.1.8, GNU coreutils | dosfstools, mtools, distribution LLVM |
| Python | 3.12.13 | 3.12 |

## Results

| step | development host | CI |
|---|---|---|
| `make check-fork` | pass: 34 files, 33 byte-identical to the pin, 1 declared divergence | pass |
| `forge build --target kernel-image` | pass: 67108864 bytes | pass |
| `forge verify-build --json` | pass: `"valid": true` | pass |
| determinism, two builds compared | pass: byte-identical | pass: byte-identical |
| QEMU matrix, 6 scenarios | 6 of 6 | 6 of 6 |
| `docs/running.md` followed end to end | pass, from a clean directory | not run |

CI run: [30779676660](https://github.com/bulla-systems/bulla/actions/runs/30779676660), 4m06s.

### Image digests

```
development host  e08db880837bb0d2a90e7d23528aeefc116423f3240e8fd09dac0ae45313cac6
CI                2ef4fdad0bef5c9b0bb88c1c5c651fb3b905be0f00364b4e36adda0fdeb33a2c
both              67108864 bytes
```

The two hosts produce different images. `deterministic_rebuilds = 2` in
`profile.toml` holds on a given host: two builds are byte-identical, on each of
the two hosts. It does not hold across hosts. Cross-compiling to
`x86_64-unknown-uefi` from an `aarch64-apple-darwin` toolchain and from an
`x86_64-unknown-linux-gnu` toolchain produces different PE bytes at the same
pinned Rust channel, the same `SOURCE_DATE_EPOCH`, and the same volume ID.

The build is host-deterministic. Re-deriving a published image requires matching
the build host as well as the source and the pin. The profile says
`deterministic_rebuilds` rather than "reproducible", so upstream claimed no more
than this; `docs/architecture.md` had read it as the stronger property, and has
been corrected.

Narrowing the gap is separate work and is not part of this pass. The likely
levers are `--remap-path-prefix`, a pinned linker, and a container-fixed
toolchain.

### Determinism

`profile.toml` claims `deterministic_rebuilds = 2`, and forge's receipt sets
`reproducible_pair_checked: true`. Both were checked from outside, since a
receipt asserting that an image is reproducible is not evidence that it is. Two
full builds per host, each from a clean checkout of the pin, a fresh overlay, and
a fresh `forge`:

```
development host  build 1: e08db880837bb0d2a90e7d23528aeefc116423f3240e8fd09dac0ae45313cac6
                  build 2: e08db880837bb0d2a90e7d23528aeefc116423f3240e8fd09dac0ae45313cac6
CI                build 1: 2ef4fdad0bef5c9b0bb88c1c5c651fb3b905be0f00364b4e36adda0fdeb33a2c
                  build 2: 2ef4fdad0bef5c9b0bb88c1c5c651fb3b905be0f00364b4e36adda0fdeb33a2c
```

On the development host, an image built from Bulla's forked tree and one built
from the unmodified pin also match. The one declared divergence is in
`test-qemu.py`, which is not an input to the image.

### QEMU/OVMF acceptance matrix

Six of six scenarios passed, each ending in `THERMITE_SUCCESS gate=boot-smp-v1`,
with `THERMITE_QEMU_MATRIX_SUCCESS cpus=1,2,4,8`. Per-scenario transcript digests
as bound into the receipt:

| CPUs | scenario | observed | transcript sha256 |
|---|---|---|---|
| 1 | nominal | `online=1 aps=0 work=2048` | `4c629976a150789000e2f5d2dea232e26f3f42dde3663e56497857a1e2f15d00` |
| 2 | nominal | `online=2 aps=1 work=4096` | `d9738cd1753790525ae03c71d045799e1d493385da95bfbf950935fef7f8ae05` |
| 4 | nominal | `online=4 aps=3 work=8192` | `33132a1e9b805bab755c3d124cb549b7398dd69ca6d343c70628a3c6ebd25580` |
| 8 | nominal | `online=8 aps=7 work=16384` | `1855aa701dcef5b5dac477031d99dbb606bb7f7e445282898054256852fad3f9` |
| 4 | ap-start-failure | `apic_id=3 state=Failed reason=injected online=3` | `c85bcba13681e509738a1d5ed22a8238c6917a4936c1893c6c2211027c1b65dd` |
| 2 | reboot | `action=reboot terminal=1` | `7e1b5180c0b43d32f0698ebc16820877fef4c21c33f79b6b001158539b59c4b5` |

No scenario was skipped.

### What `verify-build` checked

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
receipt's bindings and re-derives the proof evidence from current source. It does
not rebuild the image or re-boot it. The determinism result above comes from
`make determinism`, which is a separate check. `docs/architecture.md` previously
ran the two together and has been corrected.

### The published artifact was fetched and booted

The CI artifact was downloaded onto the development host, which did not build it,
and booted there by following [`docs/running.md`](running.md): 67108864 bytes,
digest `2ef4fdad…` matching CI's, ending in `THERMITE_SUCCESS gate=boot-smp-v1`.
Upstream built this image and discarded it; keeping and publishing it is what
this pass adds.

The GHCR push ran on tag `v0.1.1-alpha.1`
([run 30821149593](https://github.com/bulla-systems/bulla/actions/runs/30821149593)):

```
Uploaded  2ef4fdad0bef bulla.img
Pushed [registry] ghcr.io/bulla-systems/bulla:v0.1.1-alpha.1
ArtifactType: application/vnd.bulla.kernel-image.v1
Digest: sha256:178487ec2ba17f66aba803eca23deb51792488bef1d395ba842d223745ce056e
```

The round trip was then closed from the development host. `oras pull` returned
manifest `sha256:178487ec…` with two layers, `bulla.img` at 67108864 bytes under
`application/vnd.bulla.disk-image.raw` and `bulla.receipt.json` under
`application/vnd.bulla.receipt.v1+json`, carrying the pin as an annotation. The
pulled image hashes to `2ef4fdad…`, matching what CI built, and booting it by
following [`docs/running.md`](running.md) reached
`THERMITE_SUCCESS gate=boot-smp-v1` at 4 CPUs.

A published artifact has therefore been fetched from the registry by a machine
that did not build it and run there.

## Assurance carried

Unchanged from upstream, stated as tuples per
[the assurance model](assurance-model.md):

```
kernel_step: result > 0    all / incomplete / solver @ to_platform(x86_64-pc-uefi-smp-v1)
```

One clause, on one exported function, whose implementation is a boundary call to
`tpl_clock_read`. `to_platform` because the body is a frozen registry entry.
`solver` because Verus discharged it and nothing re-checked the solver.

The rest of the image, covering the scheduler, allocator, frame lifecycle,
capability ledger, IRQ, DMA and SMP, is hand-written Rust with
`none / none / fiat` and no proof obligation. The boot transcript's
`THERMITE_MODEL` line reports those models executing, which is a test result.

This pass added no verification. T0 in [the roadmap](roadmap.md) is where that
starts, and it is NOT STARTED.

## Problems found

### 1. forge's kernel-image target runs only from its own workspace

`forge build --target kernel-image` resolves the platform profile directory and
its relative output path against forge's compile-time workspace root
(`env!("CARGO_MANIFEST_DIR")/..`). There is no `--profile-root`, and `--platform`
selects a name that is then checked against a compiled-in constant.

Two checks:

- With Bulla's `platform/` directory renamed away, the documented build command
  still got past profile resolution and failed on a missing host tool. It was
  reading the other checkout's copy.
- Invoked from Bulla with `--out dist/bulla.img`, it wrote the image, the EFI
  binary, the PDB and the receipt into `<thermite-clone>/dist/`, then failed
  reading them back from Bulla's `dist/`.

A fork of the platform layer is therefore not the thing that gets built unless it
is placed inside the pinned checkout. `scripts/build-image.sh` does that in a
scratch clone. It is a workaround for a missing upstream flag; the fix is a
`--profile-root` option, which belongs upstream in Thermite.

### 2. The acceptance harness finds firmware only under three Linux paths

`test-qemu.py` searched `/usr/share/edk2/ovmf`, `/usr/share/OVMF`, and
`/usr/share/qemu`. On macOS all three are under SIP and cannot be created, so the
gate could not run whether or not QEMU and OVMF were installed. Arch Linux's
`/usr/share/edk2/x64/` is also outside the list.

Bulla's copy adds a `BULLA_OVMF_DIR` root ahead of the three, which is the fork's
one declared divergence. It changes firmware discovery. The pairs, the QEMU
command line, and every transcript assertion are untouched, so a gate that passes
here passes upstream. Worth upstreaming.

### 3. The harness requires Python 3.10 or newer, undeclared

`test-qemu.py` calls `Path.write_text(..., newline=...)`, added in Python 3.10.
Under macOS's system Python 3.9 the first scenario boots and then fails with
`TypeError: write_text() got an unexpected keyword argument 'newline'` while
writing its log, reporting a passing boot as a failure. `ubuntu-latest` has 3.12,
so upstream CI does not see it. Recorded in `docs/running.md`.

### 4. Two defects that only CI surfaced

Both are in this repository's own scripts, and both passed every local run.

- `oras` is not in Ubuntu's archives. The first CI run failed at the apt step. It
  is needed only by the tag-gated publish job, and now installs there from its
  release tarball.
- `git clone` refuses a non-empty destination, and the cache makes the
  destination non-empty. `Swatinem/rust-cache` restores `.build/thermite/target`
  before the build scripts run, so the directory exists without a `.git` and the
  clone aborts. The first CI run passed because the cache was cold; the next one
  failed. Both scripts now init-and-fetch, which works from either state.

The second is worth remembering: a green first run was not evidence that the
script worked, and local testing from a clean tree could not have caught it,
because the failure requires the state the previous success created.

### 5. `registry.toml` names a path this repository does not have

The forked `registry.toml` says `registry_source = "thermite-kernel/src/registry.rs"`.
Here that file is `kernel/src/registry.rs`. It is left unchanged: the string is
correct at build time, since `scripts/build-image.sh` overlays `kernel/` back
onto `thermite-kernel/` in the clone, and editing it would add a second
divergence for no gain.
