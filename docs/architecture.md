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

**Host-deterministic, not reproducible.** Two builds on one machine are
byte-identical; two builds on *different* machines are not. Measured: the same
source at the same pin yields different image digests from an
`aarch64-apple-darwin` toolchain and an `x86_64-unknown-linux-gnu` one. Anyone
re-deriving a published image has to match the build host too
([evidence](reproduction.md)).

The QEMU acceptance matrix is **part of this pipeline, not a separate CI step**:
`forge build --target kernel-image` runs the frozen image builder and then the
gate, and fails the build if any scenario fails. The receipt records one
transcript digest per scenario.

The receipt binds every member of both closures. `verify-build` re-checks those
bindings and re-derives the proof evidence from current source. It does **not**
rebuild the image or re-boot it unless given `--replay` — a plain
`verify-build --json` reports `"replayed": false`. Reproducibility is therefore a
separate check (`make determinism`), and is confirmed rather than inherited:
[docs/reproduction.md](reproduction.md).

One further thing a reader will hit: `forge` resolves the platform profile
directory and its output path from **its own compile-time workspace root**, not
from the current directory and not from a flag. A consumer repository cannot
simply invoke it. See [docs/upstream-pin.md](upstream-pin.md) for the mechanism
Bulla uses instead.

## Boot sequence

1. UEFI firmware loads `EFI/BOOT/BOOTX64.EFI`
2. While boot services are live: memory map, MP Services, AP discovery
3. `ExitBootServices()` — the kernel now owns the machine
4. Own page tables, GDT/IDT/TSS; AP trampoline; INIT/SIPI startup
5. Local xAPIC, per-CPU state, TSC-deadline timers
6. Scheduler, IPI round-trips, TLB shootdown, ring-3 entry, syscall and fault
7. Allocator and DMA probes, entropy, power action

All seven steps exist and pass a QEMU gate at 1/2/4/8 CPUs plus AP-start-failure
and reboot — step 7 included: the gate asserts on the allocator, DMA, entropy,
and power-action markers too. Reproduced here on 2026-08-02, six of six
scenarios: [docs/reproduction.md](reproduction.md).

**What is missing is not bring-up. It is a verified payload riding on top of it.**
Passing that gate is a *test* result. It says these code paths execute and
produce the expected transcript; it says nothing about their correctness, and
none of the subsystems it exercises are proven.

## Where the verified core plugs in

`forge build` takes `--compose-export <fn>` and `--compose-shell <file>`: the
Thermite function becomes the entry point the platform calls, and the shell is
the frozen implementation binding. Today that export is a single trivial
function — `kernel_step` in [`src/bootable_kernel.th`](../src/bootable_kernel.th),
whose whole postcondition is `result > 0`, discharged against a body that returns
a clock field. It is a link-integrity probe. It is what the published image
carries, and it is the entire proof content of that image.

[T0](roadmap.md) replaces it with the privilege state machine — the same
mechanism, carrying something worth proving.
