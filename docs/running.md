# Running the image

How to boot a published Bulla image. You need QEMU and an OVMF firmware pair.
Thermite, Verus, Rust, and this repository are not required.

## What the image does

A 64 MiB FAT32 UEFI disk image containing one file, `EFI/BOOT/BOOTX64.EFI`. It
brings up SMP, installs its own page tables, GDT/TSS/IDT and local APIC state,
starts the application processors, runs a scheduler and TLB shootdown, enters
ring 3, takes a syscall and a page fault, and powers off. It prints a serial
transcript while doing it and then halts the machine. There is no shell and no
userland. A successful run is a transcript ending in
`THERMITE_SUCCESS gate=boot-smp-v1`, followed by the VM exiting.

The image's verified payload is one function: `kernel_step` in
[`src/bootable_kernel.th`](../src/bootable_kernel.th), which reads a clock
through a boundary and returns a field, certified at L3 against
`ens result > 0`. That is the whole of the proof content. The kernel subsystems
in the image, including the scheduler, allocator, frame lifecycle and capability
ledger, are hand-written Rust and are unverified. The image carries the assurance
the upstream Thermite image carried.

The `THERMITE_*` markers in the transcript are upstream's serial protocol, kept
unchanged. See [docs/upstream-pin.md](upstream-pin.md).

## Get the image

From a tagged release, as an OCI artifact:

```sh
oras pull ghcr.io/bulla-systems/bulla:<tag>
```

That gives you `bulla.img` and `bulla.receipt.json` in the current directory.
This is a raw disk image stored in a registry, not a container image, so
`docker run` does not apply to it.

While this repository is private the package is too, and the pull needs
credentials carrying `read:packages`. The `repo` scope does not cover GHCR, so a
token without it gets `denied` even with full access to this repository:

```sh
gh auth refresh -h github.com -s read:packages   # once
gh auth token | oras login ghcr.io -u <your-github-username> --password-stdin
```

Without that scope the registry answers
`denied: requested access to the resource is denied`, which reads as a missing
artifact rather than a missing permission. If the package is later made public,
the login step goes away and `oras pull` works unauthenticated.

From a CI run, the `bulla-image-<sha>` artifact on the `ci` workflow carries the
same image plus the boot evidence.

## Get an OVMF firmware pair

QEMU needs two pflash files: a read-only code image and a writable variables
image. They must come from the same build. A 2 MiB `CODE` paired with a 4 MiB
`VARS` will hang or drop you at the firmware shell.

Bulla's acceptance harness (`platform/x86_64-pc-uefi-smp-v1/test-qemu.py`)
accepts either layout, in this order:

| pair | typical layout |
|---|---|
| `OVMF_CODE.fd` + `OVMF_VARS.fd` | 2 MiB |
| `OVMF_CODE_4M.fd` + `OVMF_VARS_4M.fd` | 4 MiB |

Either layout works for the command below, as long as the two halves match. The
invocation is identical apart from the two file paths.

| system | install | pair to use |
|---|---|---|
| Debian / Ubuntu | `sudo apt install ovmf` | `/usr/share/OVMF/OVMF_CODE_4M.fd` + `/usr/share/OVMF/OVMF_VARS_4M.fd`, checked on ubuntu-24.04, which ships the 4 MiB layout alone with no plain `OVMF_CODE.fd`. Older releases ship the 2 MiB pair instead |
| Fedora / RHEL | `sudo dnf install edk2-ovmf` | `/usr/share/edk2/ovmf/OVMF_CODE.fd` + `/usr/share/edk2/ovmf/OVMF_VARS.fd` |
| Arch | `sudo pacman -S edk2-ovmf` | `/usr/share/edk2/x64/OVMF_CODE.4m.fd` + `OVMF_VARS.4m.fd` |
| Alpine | `doas apk add ovmf` | `/usr/share/OVMF/OVMF_CODE.fd` + `/usr/share/OVMF/OVMF_VARS.fd` |
| macOS (Homebrew) | `brew install qemu` | `/opt/homebrew/share/qemu/edk2-x86_64-code.fd` + `/opt/homebrew/share/qemu/edk2-i386-vars.fd` |

Two notes:

- Arch's path is outside the set the harness searches, so `make boot-matrix` will
  not find firmware there. Set `BULLA_OVMF_DIR` to a directory holding a
  correctly named pair. The command below takes paths directly and is
  unaffected.
- On macOS the vars file is the i386 one. QEMU's edk2 build ships one variables
  image shared by the i386 and x86_64 code images, and this pairing produced the
  transcript below.

## Boot it

Copy the variables file first, since QEMU writes to it and the packaged copy is
better left alone:

```sh
cp /usr/share/OVMF/OVMF_VARS_4M.fd ./OVMF_VARS.local.fd
```

Then:

```sh
qemu-system-x86_64 \
  -machine q35,accel=tcg \
  -cpu max,-x2apic \
  -smp 4 \
  -m 256M \
  -nodefaults -no-reboot -display none -serial stdio -monitor none \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
  -drive if=pflash,format=raw,file=./OVMF_VARS.local.fd \
  -drive format=raw,if=none,id=bulla-disk,file=bulla.img \
  -device virtio-blk-pci,drive=bulla-disk,disable-modern=on
```

The image is built against these choices, which are frozen in
[`profile.toml`](../platform/x86_64-pc-uefi-smp-v1/profile.toml):

| flag | why |
|---|---|
| `-machine q35` | the profile's machine type; the PCI topology the virtio probe expects |
| `accel=tcg` | emulation rather than KVM. KVM works on an x86-64 host, but the frozen profile is TCG and that is what the acceptance evidence is from |
| `-cpu max,-x2apic` | the runtime drives the local xAPIC directly. With x2APIC enabled, APIC setup takes a path the acceptance matrix does not cover |
| `-smp 4` | any of 1, 2, 4, or 8. The transcript reports the count it found |
| `-m 256M` | the profile's memory size; the boot adapter reserves a 64-page extent below 4 GiB from it |
| `-no-reboot` | the kernel's final act is a UEFI reset. Without this, a reboot action loops instead of exiting |
| `-serial stdio` | the transcript is the only output. There is no display |
| `disable-modern=on` | the runtime drives legacy virtio-blk directly, and probes for that rather than a modern virtio device |

On an x86-64 host, `-machine q35,accel=kvm` also boots and is much faster. The
acceptance matrix uses TCG, so use TCG when reproducing its evidence.

## What a good run looks like

Boot takes a few seconds under TCG. Abridged from a run of the image built at the
pin; full transcripts land in `dist/boot-evidence/` when you use the harness:

```
THERMITE_BOOT profile=x86_64-pc-uefi-smp-v1
THERMITE_CPUS discovered=4 enabled=4
THERMITE_SMP online=4 aps=3 unique=4 work=8192 expected=8192 parallel_aps=3 stale=0 duplicate=0 bad_ids=0
THERMITE_EXIT_BOOT_SERVICES ownership=kernel
THERMITE_POST_STAGE paging=1
...
THERMITE_USER ring=3 syscall_instruction=syscall syscall=1 fault=1 resume=1
THERMITE_POWER action=poweroff terminal=1
THERMITE_SUCCESS gate=boot-smp-v1
```

The VM then exits on its own. If you see `THERMITE_SUCCESS` and QEMU is still
running, `-no-reboot` is missing.

## When it does not work

| symptom | cause |
|---|---|
| drops to a `Shell>` or `BdsDxe: failed to load Boot0001` prompt | firmware did not find `EFI/BOOT/BOOTX64.EFI`; the image is truncated or is not the raw `.img` |
| hangs with no output at all | mismatched OVMF code/vars pair, or a `VARS` file from a different layout |
| boots, then stalls after `THERMITE_CPUS` | x2APIC left enabled; check `-cpu max,-x2apic` |
| `THERMITE_FAIL stage=...` | a failure in that stage; the stage name is where to look |
| no `THERMITE_DMA` line | the disk was attached without `disable-modern=on`, or not as `virtio-blk-pci` |
| transcript is fine but QEMU never exits | `-no-reboot` is missing |

## Running the full acceptance matrix

From a checkout, with QEMU and firmware installed:

```sh
make boot-matrix                       # against dist/bulla.img
BULLA_OVMF_DIR=/path/to/firmware make boot-matrix   # if your pair is elsewhere
```

That runs nominal 1/2/4/8 CPUs, an injected AP-start failure at 4 CPUs, and a
reboot power action at 2 CPUs, writing one log per scenario to
`dist/boot-evidence/`. It is fail-closed, asserting on the transcript contents
rather than the exit code alone.

Requires Python 3.10 or newer: the harness uses `Path.write_text(newline=)`,
which 3.9 does not have. On a macOS host `/usr/bin/python3` is 3.9 and fails at
the end of the first scenario, after that boot has already succeeded.
