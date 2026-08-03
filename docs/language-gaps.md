# Language gaps

What Thermite cannot yet express that Bulla needs, with scope estimates. These
belong upstream in [Thermite](https://github.com/dollspace-gay/Thermite).

Baseline at Thermite `84d276e7`, the [upstream pin](upstream-pin.md). Counts
below were re-checked against the forked tree on 2026-08-02. Three of them were
wrong in the original survey and are corrected here.

---

## G1: `Map` lowering

Status upstream: `REQ-LOWER-COLLECTIONS-MAP-VSTD` is `not_started`.

| | syntax | lowering |
|---|---|---|
| `Vec<T>` | shipped | shipped |
| `Map<K,V>` | shipped | not started |

`Map` parses but does not lower to vstd. Since vstd already provides `Map`, this
is a lowering and spec-function problem rather than a semantics problem.

Scope: medium.

Unblocks T2 and T3. The kernel models are `BTreeMap`-heavy; counted in the forked
tree, 13 of the 19 model files reference it:

```
device 6 · smp 5 · scheduler 5 · frame 5 · dma 5 · irq 4
sync 3 · services 3 · memory 3 · event 3 · policy 2 · capability 2 · atomic 2
```

This is the highest-leverage item in the plan: one upstream requirement moves
most of the kernel from blocked to buildable.

---

## G2: no concurrency semantics

Status upstream: absent, rather than incomplete.

The effect row is `pure` or a subset of
`{read(path), write(path), net(domain), alloc, time, rand, panic, diverge}`,
plus `platform(domain)` added by the kernel work. There is no concurrency
effect, no design document, and no requirement covering it. Every occurrence of
"atomic" in the requirements registry refers to atomic *file publication*.

The kernel is concurrent throughout: application-processor startup,
inter-processor interrupts, TLB shootdown with acknowledgment masks, per-CPU
state, lock protocols, and IPC on the hot path in a microkernel.

Scope: large, and research rather than implementation. Three directions:

1. Ownership-based: one CPU may hold a capability at a time, so races become type
   errors. Cheapest, fits the existing capability model, and cannot express
   lock-free protocols.
2. An explicit atomic effect plus linearizability contracts. The richest option
   and the most work.
3. A sequential model plus an interleaving obligation: verify sequentially, then
   discharge a separate obligation that interleavings preserve the invariant.

For precedent: seL4's original verification was uniprocessor with interrupts
largely disabled in-kernel, sidestepping concurrency, and its SMP story came
later and weaker. CertiKOS took the layered-refinement route for a concurrent
kernel. This is a hard problem and should not be scoped optimistically.

Blocks T4, and with it the monolithic-scope ambition.

---

## G3: no user-defined generics

Status upstream: by design. `surface-grammar.md` REQ-8 permits exactly one
builtin generic application `NAME<T>`, and AC-3 forbids a production for
struct-as-Rust-generics.

The kernel models use const generics. `kernel/src/policy.rs:16` has
`pub struct ActionBatch<const N: usize>`, and `storage.rs` and `sync.rs` use
light generics.

Scope: medium-to-large if solved properly.

Workaround: hand-monomorphize at fixed N. A kernel has fixed limits throughout
(`maximum_cpus = 64`, `scheduler_tasks = 4096`), so this costs little. G3 is a
papercut and should not be prioritized over G1.

---

## Not gaps

The kernel models are `unsafe`-free, and enforced as such: the one occurrence of
the word in `kernel/src/lib.rs` is `#![forbid(unsafe_code)]` at line 2. The
original survey read that attribute as an instance of what it forbids and
reported "one `unsafe` in `lib.rs`".

Checked against the forked tree: zero `unsafe` blocks across all 19 model files,
no traits, and the only raw pointers are three ASCII signature strings in
`registry.rs` describing `memcpy`, `memmove` and `memset`. This is data-structure
and logic code, which is the kind Thermite handles.

The obstacle to verifying this kernel is collections and concurrency rather than
unsafety or hardware.
