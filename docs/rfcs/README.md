# Provisional RFCs for Thermite

Language proposals, each matched to a rung of [the ladder](../the-ladder.md).

**Status of every document here: provisional, and ours.** None has been proposed
upstream. Thermite is not our project, seven issues are open and unanswered, and
its author is refactoring. These exist so that when a proposal is worth making it
is already worked out, and so the reasoning survives if it never is.

What we do file upstream is **defects with reproductions**, which is a
contribution rather than a request. RFC-1 is the only one currently in that
state.

| RFC | rung | proposes | kind |
|---|---|---|---|
| [000](000-surface-conventions.md) | all | surface conventions every other RFC assumes | **cross-cutting** |
| [001](001-structured-spec-surface.md) | 1, 2 | complete the spec surface of structured data | **defect report** — four items, all reproduced |
| [002](002-verified-effect-rows.md) | 3 | make effect rows verified rather than asserted; regions | extension |
| [003](003-resource-invariants.md) | 4 | invariant-guarded shared state | extension |
| [004](004-linear-types.md) | 5 | surface Verus's linear ghost state | extension |
| [005](005-interference-clauses.md) | 6 | `concurrent { asks / promises }` for interference | extension |
| [006](006-protocol-types.md) | 7 | channel protocols; endpoints as `provides` / `uses` | extension |
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

Recorded in full in [RFC-000](000-surface-conventions.md). In brief: **full
words, not abbreviations**, because Thermite is written principally by agents and
abbreviations misdirect rather than merely fail to help. Symbols are kept only
where the symbol *is* the concept — `->`, `=>`, `|x|`, `!` for the effect row,
and the operators.

Documents 001-007 predate RFC-000 and still show the older surface in places;
RFC-000 governs where they disagree.
