# Language gaps

What Thermite cannot yet express that Bulla needs, with scope estimates. These
belong upstream in [Thermite](https://github.com/dollspace-gay/Thermite), not
here.

Baseline surveyed at Thermite `84d276e7`.

---

## G1 — `Map` lowering

**Status upstream:** `REQ-LOWER-COLLECTIONS-MAP-VSTD` is `not_started`.

| | syntax | lowering |
|---|---|---|
| `Vec<T>` | shipped | **shipped** |
| `Map<K,V>` | shipped | **not started** |

`Map` parses but does not lower to vstd. Since vstd already provides `Map`, this
is a lowering and spec-function problem rather than a semantics problem.

**Scope:** medium.

**Unblocks:** T2 and T3 — roughly seven kernel subsystems. The kernel models are
`BTreeMap`-heavy: `dma` (7 references), `device` (6), `frame` (6), `smp` (5),
`scheduler` (5), `memory` (4), `irq` (4).

**This is the highest-leverage item in the entire plan.** One upstream
requirement converts most of the kernel from blocked to buildable.

---

## G2 — No concurrency semantics

**Status upstream:** does not exist. Not "incomplete" — absent.

The effect row is `pure` or a subset of
`{read(path), write(path), net(domain), alloc, time, rand, panic, diverge}`,
plus `platform(domain)` added by the kernel work. There is no concurrency
effect, no design document, and no requirement covering it. Every occurrence of
"atomic" in the requirements registry refers to atomic *file publication*.

Meanwhile the kernel is inherently concurrent: application-processor startup,
inter-processor interrupts, TLB shootdown with acknowledgment masks, per-CPU
state, lock protocols, and — in a microkernel — IPC on the hot path.

**Scope:** large. Research, not implementation. Plausible directions:

1. **Ownership-based** — only one CPU may hold a capability at a time; races
   become type errors. Cheapest, and fits the existing capability model, but
   cannot express lock-free protocols.
2. **Explicit atomic effect plus linearizability contracts** — richest, and the
   most work.
3. **Sequential model plus an interleaving obligation** — verify sequentially,
   discharge a separate obligation that interleavings preserve the invariant.

Worth noting as precedent: seL4's original verification was uniprocessor with
interrupts largely disabled in-kernel — concurrency was deliberately sidestepped,
and the SMP story came later and weaker. CertiKOS took the layered-refinement
route for a concurrent kernel. This is a genuinely hard problem and should not be
scoped optimistically.

**Blocks:** T4, and therefore the monolithic-scope ambition.

---

## G3 — No user-defined generics

**Status upstream:** by design. `surface-grammar.md` REQ-8 permits exactly one
builtin generic application `NAME<T>`; AC-3 explicitly forbids a production for
struct-as-Rust-generics.

The kernel models use const generics — `policy.rs` has
`ActionBatch<const N: usize>` — and light generics in `storage.rs` and `sync.rs`.

**Scope:** medium-to-large if solved properly.

**Workaround:** hand-monomorphize at fixed N. This is entirely acceptable for a
kernel, which has fixed limits everywhere by nature (`maximum_cpus = 64`,
`scheduler_tasks = 4096`). G3 is a papercut, not a blocker, and should not be
prioritized over G1.

---

## Not gaps

Worth recording explicitly, because it was the pleasant surprise of the survey:
the kernel models are **essentially `unsafe`-free** — one `unsafe` in `lib.rs`,
no raw pointers outside the registry, no traits. They are pure data-structure and
logic code, which is exactly what Thermite is for.

The obstacle to verifying this kernel was never unsafety or hardware. It is
collections and concurrency.
