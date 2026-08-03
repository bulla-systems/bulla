# Running the image

How to boot a published Bulla image. You need QEMU and an OVMF firmware pair.
You do **not** need Thermite, Verus, Rust, or anything in this repository.

## What you are about to boot, exactly

A 64 MiB FAT32 UEFI disk image containing one file, `EFI/BOOT/BOOTX64.EFI`. It
brings up SMP, installs its own page tables, GDT/TSS/IDT and local APIC state,
starts the application processors, runs a scheduler and TLB shootdown, enters
ring 3, takes a syscall and a page fault, and powers off. It prints a serial
transcript while doing it and then halts the machine. There is no shell, no
userland, and nothing to interact with — a successful run is a transcript ending
in `THERMITE_SUCCESS gate=boot-smp-v1` followed by the VM exiting.

**Assurance carried: one function.** The image's verified payload is
`kernel_step` in [`src/bootable_kernel.th`](../src/bootable_kernel.th) — it reads
a clock through a boundary and returns a field, certified at L3 against
`ens result > 0`. That is the entire proof content. Every kernel subsystem in the
image — the scheduler, the allocator, the frame lifecycle, the capability
ledger — is ordinary hand-written Rust and is **not verified**. The image carries
exactly the assurance the upstream Thermite image carried, and this pass added
none.

The `THERMITE_*` markers in the transcript are upstream's serial protocol, kept
unchanged on purpose — see [docs/upstream-pin.md](upstream-pin.md).

## Get the image

From a tagged release, as an OCI artifact:

```sh
oras pull ghcr.io/bulla-systems/bulla:<tag>
```

That gives you `bulla.img` and `bulla.receipt.json` in the current directory. It
is **not** a container image — `docker run` on it is meaningless. It is a raw
disk image stored in a registry because registries are a convenient place to put
bytes.

From a CI run, the `bulla-image-<sha>` artifact on the `ci` workflow carries the
same image plus the boot evidence.

## Get an OVMF firmware pair

QEMU needs two pflash files: a read-only **code** image and a writable
**variables** image. They must come from the **same** build — a 2 MiB `CODE`
paired with a 4 MiB `VARS` will hang or drop you at the firmware shell.

Bulla's acceptance harness (`platform/x86_64-pc-uefi-smp-v1/test-qemu.py`)
accepts either layout, in this order:

| pair | typical layout |
|---|---|
| `OVMF_CODE.fd` + `OVMF_VARS.fd` | 2 MiB |
| `OVMF_CODE_4M.fd` + `OVMF_VARS_4M.fd` | 4 MiB |

**Which you need for the raw command below: either, as long as the two halves
match.** The invocation is identical apart from the two file paths.

| system | install | pair to use |
|---|---|---|
| Debian / Ubuntu | `sudo apt install ovmf` | `/usr/share/OVMF/OVMF_CODE_4M.fd` + `/usr/share/OVMF/OVMF_VARS_4M.fd` (older releases ship the 2 MiB `OVMF_CODE.fd` + `OVMF_VARS.fd` instead) |
| Fedora / RHEL | `sudo dnf install edk2-ovmf` | `/usr/share/edk2/ovmf/OVMF_CODE.fd` + `/usr/share/edk2/ovmf/OVMF_VARS.fd` |
| Arch | `sudo pacman -S edk2-ovmf` | `/usr/share/edk2/x64/OVMF_CODE.4m.fd` + `OVMF_VARS.4m.fd` |
| Alpine | `doas apk add ovmf` | `/usr/share/OVMF/OVMF_CODE.fd` + `/usr/share/OVMF/OVMF_VARS.fd` |
| macOS (Homebrew) | `brew install qemu` | `/opt/homebrew/share/qemu/edk2-x86_64-code.fd` + `/opt/homebrew/share/qemu/edk2-i386-vars.fd` |

Two notes worth having before you hit them:

- **Arch's path is not one the harness searches.** `make boot-matrix` will not
  find firmware there; set `BULLA_OVMF_DIR` to a directory holding a correctly
  named pair. The raw command below is unaffected — you pass paths directly.
- **On macOS the vars file is the i386 one.** That is not a mistake: QEMU's edk2
  build ships one variables image shared by the i386 and x86_64 code images.
  This pairing is what the transcript at the bottom of this page was produced
  with.

## Boot it

Copy the variables file first — QEMU writes to it, and you want the packaged one
left alone:

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

Every flag that is not obvious is load-bearing, and the image is built against
these exact choices — they are frozen in
[`profile.toml`](../platform/x86_64-pc-uefi-smp-v1/profile.toml):

| flag | why |
|---|---|
| `-machine q35` | the profile's machine type; the PCI topology the virtio probe expects |
| `accel=tcg` | emulation rather than KVM. KVM works on an x86-64 host, but the frozen profile is TCG and that is what the acceptance evidence is from |
| `-cpu max,-x2apic` | the runtime drives the **local xAPIC** directly. Leave x2APIC enabled and APIC setup takes a different path than the one tested |
| `-smp 4` | any of 1, 2, 4, or 8. The transcript reports the count it found |
| `-m 256M` | the profile's memory size; the boot adapter reserves a 64-page extent below 4 GiB from it |
| `-no-reboot` | the kernel's final act is a UEFI reset. Without this, a reboot action loops instead of exiting |
| `-serial stdio` | the transcript is the only output. There is no display |
| `disable-modern=on` | the runtime drives **legacy** virtio-blk directly. A modern virtio device is not what it probes |

Running on an x86-64 host, `-machine q35,accel=kvm` boots too and is much
faster. It is not what the acceptance matrix uses, so if you are checking
evidence rather than just looking, use TCG.

## What a good run looks like

Boot takes a few seconds under TCG. Abridged, from an actual run of the image
built at the pin (full transcripts land in `dist/boot-evidence/` when you use the
harness):

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
| drops to a `Shell>` or `BdsDxe: failed to load Boot0001` prompt | firmware did not find `EFI/BOOT/BOOTX64.EFI` — the image is truncated or is not the raw `.img` |
| hangs with no output at all | mismatched OVMF code/vars pair, or a `VARS` file from a different layout |
| boots, then stalls after `THERMITE_CPUS` | x2APIC left enabled — check `-cpu max,-x2apic` |
| `THERMITE_FAIL stage=...` | a real failure in that stage; the stage name is the place to look |
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
`dist/boot-evidence/`. It is fail-closed: it asserts on the transcript contents,
not just the exit code.

Requires **Python 3.10 or newer** — the harness uses `Path.write_text(newline=)`,
which does not exist in 3.9. On a macOS host, `/usr/bin/python3` is 3.9 and will
fail at the end of the first scenario, after the boot has already succeeded.
