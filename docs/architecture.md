# Architecture

How a Thermite program becomes a bootable image, and where the trust boundary
sits.

## Four layers

| layer | contents | assurance |
|---|---|---|
| verified core | resource policy, capability ledger, allocators, schedulers, protocols, syscall logic | proven Thermite, per-clause certified |
| boundary registry | the frozen inventory of privileged operations, each with a contract | trusted, and enumerable |
| target platform layer (TPL) | entry stubs, trap and context assembly, privileged instructions, MMIO/PIO, page-table and CPU control | trusted; reviewed rather than proven |
| image closure | compiler runtime, linker, boot adapter, firmware ABI, packager | digest-bound build evidence |

The verified core is the layer that grows. The other three stay small enough to
read end to end, which is the claim the project rests on.

## The boundary mechanism

A privileged operation cannot be called from Thermite except through a declared
boundary:

```rust
#[boundary("kernel::clock::read@v1")]
fn clock_read(clock: Clock) -> Instant
  req true
  ens result.scale_numerator > 0
  fx platform(clock);
```

At build time this declaration is matched against exactly one frozen registry
entry, on fifteen fields:

```
name + signature + source-contract-sha256 + domain + secondary-domains
+ capability + rights + symbol + abi + alignment + ownership + model
+ concurrency + failure + evidence
```

The registry's policies are fail-closed by construction:

```toml
unknown_entry_policy     = "reject"
duplicate_entry_policy   = "reject"
arbitrary_boundary_policy = "reject"
unreachable_entry_policy = "reject-for-complete-profile"
```

An undeclared boundary fails the build, and so does a declared boundary that does
not match a registry entry on all fifteen fields. A privileged operation absent
from the registry cannot enter the kernel. Verus proves each caller against the
boundary's contract, and the implementation closure binds the declaration to one
frozen symbol.

This mechanism exists upstream and works. What it lacked was a verified core to
carry through it.

## Capabilities

Authority is carried by sealed types rather than ambient permission. The
`x86_64-pc-uefi-smp-v1` profile declares nineteen kinds:

```
BootInfo · Cpu · CpuSet · CpuLocal · PhysRegion · Frame · VirtRegion
AddressSpace · Mmio · IoPort · Irq · IrqState · TrapFrame · UserContext
Dma · IommuDomain · Clock · Entropy · Power
```

MMIO access requires holding an `Mmio`. Capabilities are generation-tagged, so a
stale reference is detectable rather than a use-after-free, which is
[MWE property P2](mwe-context.md#the-claims).

Twelve domains organize the 104 registry operations: `boot`, `memory`, `mmio`,
`pio`, `irq`, `cpu`, `atomic`, `smp`, `dma`, `clock`, `entropy`, `power`.

## Build pipeline

```
  src/*.th
        │  forge build --target kernel-image --platform <profile>
        ▼
  proof closure ───────────► implementation closure
  (Verus proves callers      (registry resolves each boundary to
   against boundary            exactly one frozen body; source and
   contracts)                  symbol inventory bound)
        │                              │
        └──────────► receipt ◄─────────┘
                        │
                        ▼
              FAT32 UEFI disk image
              host-deterministic: rebuilt twice and compared,
              SOURCE_DATE_EPOCH and volume ID pinned
```

Determinism has two levels here, and they are not the same claim.

On a bare host the build is **host-deterministic**: two builds on one machine are
byte-identical, and two builds on different machines are not. The same source at
the same pin yields different digests from an `aarch64-apple-darwin` toolchain
and an `x86_64-unknown-linux-gnu` one, because the divergence is in the host
build of the toolchain rather than in the source, the flags, or the compiler
version.

Through [`Containerfile`](../Containerfile), which pins the toolchain by digest,
the build is **reproducible across hosts**: macOS/arm64 under emulation and
ubuntu-24.04/x86-64 produce the same image. Re-deriving a published image
therefore needs the source, the pin, and the container digest
([evidence](reproduction.md)).

The QEMU acceptance matrix runs inside this pipeline rather than as a separate CI
step. `forge build --target kernel-image` runs the frozen image builder and then
the gate, failing the build if any scenario fails. The receipt records one
transcript digest per scenario.

The receipt binds every member of both closures. `verify-build` re-checks those
bindings and re-derives the proof evidence from current source. Without
`--replay` it does not rebuild the image or re-boot it, and reports
`"replayed": false`. Determinism is a separate check, `make determinism`, whose
result is in [docs/reproduction.md](reproduction.md).

`forge` resolves the platform profile directory and its output path from its own
compile-time workspace root, rather than from the current directory or a flag, so
a consumer repository cannot invoke it directly.
[docs/upstream-pin.md](upstream-pin.md) describes the mechanism Bulla uses.

## Boot sequence

1. UEFI firmware loads `EFI/BOOT/BOOTX64.EFI`
2. While boot services are live: memory map, MP Services, AP discovery
3. `ExitBootServices()`, after which the kernel owns the machine
4. Own page tables, GDT/IDT/TSS; AP trampoline; INIT/SIPI startup
5. Local xAPIC, per-CPU state, TSC-deadline timers
6. Scheduler, IPI round-trips, TLB shootdown, ring-3 entry, syscall and fault
7. Allocator and DMA probes, entropy, power action

All seven steps pass a QEMU gate at 1/2/4/8 CPUs plus AP-start-failure and
reboot. Step 7 is included: the gate asserts on the allocator, DMA, entropy and
power-action markers. Reproduced here on 2026-08-02, six of six scenarios:
[docs/reproduction.md](reproduction.md).

Bring-up is present; a verified payload on top of it is what remains. Passing
that gate is a test result: it shows the code paths execute and produce the
expected transcript, and says nothing about their correctness. None of the
subsystems it exercises are proven.

## Where the verified core plugs in

`forge build` takes `--compose-export <fn>` and `--compose-shell <file>`. The
Thermite function becomes the entry point the platform calls, and the shell is
the frozen implementation binding. That export is currently `kernel_step` in
[`src/bootable_kernel.th`](../src/bootable_kernel.th), whose postcondition is
`result > 0`, discharged against a body that returns a clock field. It is a
link-integrity probe, and it is the whole of the published image's proof content.

[T0](roadmap.md) replaces it with the privilege state machine, through the same
mechanism.
