# Provisional RFCs for Thermite

Language proposals, each matched to a rung of [the ladder](../the-ladder.md).

**Status of every document here: provisional, and ours.** None has been proposed
upstream. Thermite is not our project, seven issues are open and unanswered, and
its author is refactoring. These exist so that when a proposal is worth making it
is already worked out, and so the reasoning survives if it never is.

What we do file upstream is **defects with reproductions**, which is a
contribution rather than a request. The spec-surface document is the only one
currently in that state.

| document | rung | proposes | kind |
|---|---|---|---|
| [surface conventions](surface-conventions.md) | all | the clause grammar and surface every other document assumes | **cross-cutting** |
| [structured spec surface](structured-spec-surface.md) | 1, 2 | complete the spec surface of structured data | **defect report** — four items, all reproduced |
| [verified effect rows](verified-effect-rows.md) | 3 | make effect rows verified rather than asserted | extension |
| [shared-state invariants](shared-state-invariants.md) | 4 | invariant-guarded shared state | extension |
| [resource types](resource-types.md) | 5 | surface Verus's linear ghost state as `resource` | extension |
| [interference clauses](interference-clauses.md) | 6 | `interleaves { asks / promises }` | extension |
| [protocol types](protocol-types.md) | 7 | channel protocols; endpoints as `provides` / `uses` | extension |
| [the crash clause](crash-clause.md) | — | `survives`, for durable state | extension |

## Why these are not numbered

They were, and the numbers collided with Thermite's own.

Thermite allocates RFC numbers in its **GitHub issues**:
[RFC-1](https://github.com/dollspace-gay/Thermite/issues/2) (Thermite 2 — a
dependent-type tier, a stratified cage, and new ladder boundaries),
[RFC-2](https://github.com/dollspace-gay/Thermite/issues/119) (the certification
surface), and [RFC-3](https://github.com/dollspace-gay/Thermite/issues/120)
(versioning). This directory's `001`–`003` sat on top of all three, and
[the assurance model](../assurance-model.md) cites *upstream's* RFC-2 while this
directory held a different one under the same name.

Renumbering into the same sequence moves the collision rather than removing it,
because two authorities allocating from one counter is what produced it. A number
in that namespace is an upstream allocation, and by the paragraph above none of
these has been proposed, so claiming one is claiming what nobody granted.

So identity here is a **slug**. A document filed upstream gains its number there,
recorded in the document, while its local identity stays the name.

The previous numbering, for citations that predate this change:

| was | is |
|---|---|
| RFC-000 | [surface conventions](surface-conventions.md) |
| RFC-001 | [structured spec surface](structured-spec-surface.md) |
| RFC-002 | [verified effect rows](verified-effect-rows.md) |
| RFC-003 | [shared-state invariants](shared-state-invariants.md), retitled from "Resource invariants" |
| RFC-004 | [resource types](resource-types.md), retitled from "Linear types" |
| RFC-005 | [interference clauses](interference-clauses.md) |
| RFC-006 | [protocol types](protocol-types.md) |
| RFC-007 | [the crash clause](crash-clause.md) |

Both retitles are forced by the same decision: `resource` now names linearity, so
a document about lock-guarded shared state could not keep the word.

## The thread running through them

Every proposal here is either **a defect in something that already exists**, or
**an extension to a clause the language already requires** — never a new
subsystem bolted on.

- The spec-surface document fixes emitters for collections and recursive data
  that already lower.
- Verified effect rows makes `fx` checkable, which it currently is not, and gets
  race-freedom as a consequence.
- Shared-state invariants reuses `inv`.
- Resource types surfaces `Tracked`, which the pinned Verus already ships.
- Interference clauses adds two clauses shaped like `req`/`ens`.
- The crash clause adds one clause shaped like `ens`.

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

Recorded in full in [the surface conventions](surface-conventions.md). In brief:
**full words, not abbreviations**, because Thermite is written principally by
agents and abbreviations misdirect rather than merely fail to help. Every clause
is a third-person-singular verb whose subject is the item. Symbols are kept only
where the symbol *is* the concept — `->`, `=>`, `|x|`, `!` for the effect row,
and the operators.

Every document except the surface conventions predates that pass and still shows
the older surface in places; the surface conventions govern where they disagree.
