# Architecture

How a Thermite program becomes a bootable image, and where the trust boundary
sits.

## Four layers

| layer | contents | assurance |
|---|---|---|
| **verified core** | resource policy, capability ledger, allocators, schedulers, protocols, syscall logic | proven Thermite, per-clause certified |
| **boundary registry** | the frozen inventory of privileged operations, each with a contract | **trusted, and enumerable** |
| **target platform layer (TPL)** | entry stubs, trap and context assembly, privileged instructions, MMIO/PIO, page-table and CPU control | trusted; reviewed, not proven |
| **image closure** | compiler runtime, linker, boot adapter, firmware ABI, packager | digest-bound build evidence |

The verified core is the only layer that grows. The other three are meant to
stay small and be readable end to end — that is the whole claim.

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

At build time this declaration is matched against **exactly one** frozen registry
entry on fifteen fields:

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

The consequence that matters: **you cannot smuggle a privileged operation into
the kernel.** An undeclared boundary fails the build; a declared boundary that
does not match a registry entry exactly fails the build. Verus proves each
*caller* against the boundary's contract, and the implementation closure binds
that declaration to one frozen symbol.

This is the mechanism the entire project rests on, and it already exists and
works. What did not exist was a verified core worth carrying through it.

## Capabilities

Authority is carried by sealed types rather than ambient permission. The
`x86_64-pc-uefi-smp-v1` profile declares nineteen kinds:

```
BootInfo · Cpu · CpuSet · CpuLocal · PhysRegion · Frame · VirtRegion
AddressSpace · Mmio · IoPort · Irq · IrqState · TrapFrame · UserContext
Dma · IommuDomain · Clock · Entropy · Power
```

You cannot touch MMIO without holding an `Mmio`. Capabilities are
generation-tagged, so a stale reference is detectable rather than a
use-after-free — which is [MWE property P2](mwe-context.md#the-claims).

Twelve domains organize the 104 registry operations: `boot`, `memory`, `mmio`,
`pio`, `irq`, `cpu`, `atomic`, `smp`, `dma`, `clock`, `entropy`, `power`.

## Build pipeline

```
  conformance/*.th
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
              deterministic: rebuilt twice and compared,
              SOURCE_DATE_EPOCH and volume ID pinned
```

The receipt binds every member of both closures. `verify-build` re-checks it,
and the image is republishable byte-for-byte from tracked source.

## Boot sequence

1. UEFI firmware loads `EFI/BOOT/BOOTX64.EFI`
2. While boot services are live: memory map, MP Services, AP discovery
3. `ExitBootServices()` — the kernel now owns the machine
4. Own page tables, GDT/IDT/TSS; AP trampoline; INIT/SIPI startup
5. Local xAPIC, per-CPU state, TSC-deadline timers
6. Scheduler, IPI round-trips, TLB shootdown, ring-3 entry, syscall and fault
7. Allocator and DMA probes, entropy, power action

Steps 1–6 exist and pass a QEMU gate at 1/2/4/8 CPUs plus AP-failure and reboot.
**What is missing is not bring-up. It is a verified payload riding on top of it.**

## Where the verified core plugs in

`forge build` takes `--compose-export <fn>` and `--compose-shell <file>`: the
Thermite function becomes the entry point the platform calls, and the shell is
the frozen implementation binding. Today that export is a single trivial
function.

[T0](roadmap.md) replaces it with the privilege state machine — the same
mechanism, carrying something worth proving.
