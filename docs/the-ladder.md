# The ladder

Bulla's position is not a fixed point between microkernel and monolith. It is a
**rung**, and the project's work is climbing.

Each rung is a proof capability the language either has or lacks. Each rung moves
a specific kernel affordance from *"an unverified guest provides it"* to *"the
verified core provides it"*. That makes the position measurable rather than a
slogan, and it gives every gap we file a place in an order.

This document is the roadmap. [architecture.md](architecture.md) is the design it
implements; [docs/rfcs/](rfcs/) holds the language proposals each rung needs.

## The rungs

| rung | proof capability | language work | the system you could ship |
|---|---|---|---|
| **0** | scalar invariants | — *(have it)* | fixed programs in isolation, one CPU. Not a Unix. |
| **1** | structural predicates over recursive data | [the spec surface](rfcs/structured-spec-surface.md) | **a Unix, running unverified, inside a verified box** |
| **2** | predicates over bounded collections | [the spec surface](rfcs/structured-spec-surface.md) | **a decomposed Unix** — isolated servers, capability-mediated, faults contained |
| **3** | checked effect rows over shared state | [verified effect rows](rfcs/verified-effect-rows.md) | the same, **multi-core** |
| **4** | invariant-guarded shared state | [shared-state invariants](rfcs/shared-state-invariants.md) | shared kernel structures under proven locks |
| **5** | linear types | [resource types](rfcs/resource-types.md) | **dynamic processes and memory — Unix's core mechanisms verified** |
| **6** | interference relations | [interference clauses](rfcs/interference-clauses.md) | the same, without serialising the hot paths |
| **7** | protocol types | [protocol types](rfcs/protocol-types.md) | server decomposition verified end to end |

Beyond those, three directions the mathematics points at that would make this a
novel kernel rather than a proven instance of a familiar one:

| | capability | why it is research |
|---|---|---|
| **8** | noninterference | a hyperproperty — about *sets* of executions, not one. seL4 proved it for static configurations; dynamic authority is open |
| **9** | cost as an effect | proven worst-case execution time rather than measured. Addresses the weakest link in real-time certification |
| **10** | an algebra for composing certificates | [already identified as open in-repo](assurance-model.md#aggregation-is-unspecified). Needs no language change at all |
| **11** | distributional effects | stipulate a distribution on a source input, certify the output's. The surface is reachable now — [`random` is designed to accept a parameter later](rfcs/effect-algebra.md#what-the-criterion-kept-differently-random), so `random(D)` is not a breaking change — and the discharge needs the convex algebra and enough measure theory to push distributions through a solver that has none. It is what a cryptographic argument requires |

## Why the order is what it is

**Rung 1 is the largest capability jump per unit of work anywhere on the ladder.**
It is an emitter fix — a recursive `spec fn` over an ADT has its declared `bool`
return type rewritten to `nat`. That single defect is the difference between
"isolated fixed programs" and "can host a real operating system", because it is
what lets the kernel *validate a page table it was handed* rather than only build
one itself.

**Rung 3 is a multiplier, not an adder.** Every other rung adds an affordance.
Rung 3 takes everything already proven and makes it valid on multiple CPUs, via
the data-race-freedom-implies-sequential-consistency theorem. It is also the only
rung whose check is purely syntactic — no solver, no new proof obligations.

**Rung 5 is the honest goal.** Everything below it produces a system where Unix
runs *beside* the verified part. Reusable allocation is what `fork`, `exec`,
demand paging and copy-on-write all need, so it is the rung where a verified Unix
kernel becomes conceivable rather than a verified box around an unverified one.

**Rung 6 buys no functionality.** It removes the reason someone would reject the
kernel on performance grounds, which is a different and later problem.

## What stays outside, and why

Worth stating precisely, because it bounds the project.

| | why it is outside | is it different mathematics? |
|---|---|---|
| crash consistency | needs a crash relation and a recovery obligation | **No.** Crash Hoare Logic (FSCQ, 2015) adds a third clause to the Hoare triple. It is a rung we have not scheduled, not a barrier — see [the crash clause](rfcs/crash-clause.md) |
| POSIX semantics | thousands of behaviours, many historical accidents, no canonical formal spec | **No.** Ordinary safety properties. Outside for cost, not mathematics |
| device drivers | needs a hardware model per device | Different, and expensive per driver. Capsules are the only route |
| **liveness and fairness** | "something good eventually happens" | **Yes.** Safety properties are violated by a finite prefix; liveness only by infinite behaviour. Needs ranking functions, fairness assumptions and temporal logic rather than invariants |

Liveness is the one genuine exception. Everything else on that list is scheduling
or economics.

Even at rung 7 the honest ceiling is: a verified kernel with unverified
filesystems and drivers, hosting a POSIX personality that is tested rather than
proven.

## Where we are

**Rung 0.** Everything above it is NOT STARTED, with the blocker named.

The immediate blockers are [G4](language-gaps.md#g4-struct-fields-of-user-declared-types)
([#122](https://github.com/dollspace-gay/Thermite/issues/122)) for the data model
and the rung-1 emitter defect. Both are small; neither is ours to fix.
