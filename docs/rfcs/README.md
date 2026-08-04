# Provisional RFCs for Thermite

Language proposals, each matched to a rung of [the ladder](../the-ladder.md).

**Status of every document here: provisional, and ours.** None has been proposed
upstream. Thermite is not our project, seven issues are open and unanswered, and
its author is refactoring. These exist so that when a proposal is worth making it
is already worked out, and so the reasoning survives if it never is.

What we do file upstream is **defects with reproductions**, which is a
contribution rather than a request. RFC-1 is the only one currently in that
state.

| [000](000-surface-conventions.md) | all | surface conventions every other RFC assumes | **cross-cutting** |

| RFC | rung | proposes | kind |
|---|---|---|---|
| [001](001-structured-spec-surface.md) | 1, 2 | complete the spec surface of structured data | **defect report** — four items, all reproduced |
| [002](002-verified-effect-rows.md) | 3 | make effect rows verified rather than asserted; regions | extension |
| [003](003-resource-invariants.md) | 4 | invariant-guarded shared state | extension |
| [004](004-linear-types.md) | 5 | surface Verus's linear ghost state | extension |
| [005](005-interference-clauses.md) | 6 | `<~` and `~>` for concurrent interference | extension |
| [006](006-protocol-types.md) | 7 | channel protocols with duality | extension |
| [007](007-crash-clause.md) | — | a `crash` clause for durable state | extension |

## The thread running through them

Every proposal here is either **a defect in something that already exists**, or
**an extension to a clause the language already requires** — never a new
subsystem bolted on.

- RFC-1 fixes emitters for collections and recursive data that already lower.
- RFC-2 makes `fx` checkable, which it currently is not, and gets race-freedom as
  a consequence.
- RFC-3 reuses `inv`.
- RFC-4 surfaces `Tracked`, which the pinned Verus already ships.
- RFC-5 adds two clauses shaped like `req`/`ens`.
- RFC-7 adds one clause shaped like `ens`.

That is deliberate. A proposal that strengthens an existing feature is one a
maintainer can evaluate; a proposal that adds a subsystem is one they have to
adopt.

## The metatheory position

Worth stating once rather than in each document. For every proposal here, **the
mathematics is settled and mostly already implemented in the substrate Thermite
compiles to.** The pinned Verus ships `tokens.rs` (linear ghost state),
`atomic_ghost.rs`, `invariant.rs`, `rwlock.rs`, `thread.rs`, and
`state_machines_macros`.

So none of these are "invent a semantics". They are surface syntax and lowering
over machinery that exists. The exception is the research directions in
[the ladder](../the-ladder.md#the-rungs) — noninterference, cost effects, and the
certificate algebra — which are genuinely open.

One honest caveat carried from `vstd/tokens.rs` itself:

> the `tokenized_state_machine!` macro creates **trusted** implementations of all
> these traits… the properties of these types is still assumed by the Verus
> macro, so they're still mostly trusted.

A release rule that blocks axioms and `assume` needs a considered position on
that trusted core. It is not disqualifying, and it should not be discovered late.

## Syntactic conventions used throughout

Superseded in detail by [RFC-000](000-surface-conventions.md), which records the
full-words decision and its rationale. Summary retained here:

Chosen to match what the language already does, not to be novel.

| | |
|---|---|
| clause names | 3–4 characters, lowercase, like `req` `ens` `fx` `inv` `dec` |
| effect atoms | `verb(resource)`, like the existing `read(path)` `write(path)` `net(domain)` |
| absence | never an implicit default; a missing mandatory clause is a parse error |
| arrows | straight `->` `<-` for **messages**; squiggly `~>` `<~` for **state drift** |

Every clause answers a question:

| clause | question |
|---|---|
| `req` | what must hold to call me? |
| `ens` | what holds when I return? |
| `<~` | what may change under me while I run? |
| `~>` | what do I change, and nothing else? |
| `crash` | what holds if I die partway? |
| `fx` | what do I touch? |
| `inv` | what is always true of this type? |
| `dec` | why do I terminate? |
