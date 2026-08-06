# Provisional RFCs for Thermite

Language proposals, each matched to a rung of [the ladder](../the-ladder.md).
[Thermite 3](thermite-3.md) sequences them and is the one to read first.

**Status of every document here: provisional.** None has been proposed upstream
yet. They are worked out here first so that a proposal arrives finished rather
than as a sketch, and so the reasoning survives if one is never made.

Bulla is Thermite's demanding consumer rather than an outside petitioner — the
gaps in this directory were found by trying to build a kernel against the pin,
and this repository shares a maintainer with Thermite. What that buys is not
deference; it is that a proposal here can be evaluated on the design rather than
on who is asking.

What we do file upstream is **defects with reproductions**, which is a
contribution rather than a request. The spec-surface document is the only one
currently in that state.

| document | rung | proposes | kind |
|---|---|---|---|
| [Thermite 3](thermite-3.md) | all | the surface in full, each construct marked by when it lands, plus the rollout | **specification** |
| [full words](full-words-anchor.md) | — | the anchor itself: rename and reorder, no new expressive power | **proposal** |
| [implementing the anchor](anchor-implementation.md) | — | a measured work plan for it, scoped against the tree | **plan** |
| [surface conventions](surface-conventions.md) | all | the clause grammar and surface every other document assumes | **cross-cutting** |
| [the effect algebra](effect-algebra.md) | all | what an effect *is*: a theory, a basis, and the criterion for admitting one | **cross-cutting** |
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
[#2](https://github.com/dollspace-gay/Thermite/issues/2) (Thermite 2 — a
dependent-type tier, a stratified cage, and new ladder boundaries),
[#17](https://github.com/dollspace-gay/Thermite/issues/17) (the canonical REQ
registry, filed without a number),
[#119](https://github.com/dollspace-gay/Thermite/issues/119) (the certification
surface), and [#120](https://github.com/dollspace-gay/Thermite/issues/120)
(versioning). This directory's `001`–`003` sat on top of them, and
[the assurance model](../assurance-model.md) cites upstream's certification-surface
RFC while this directory held a different one under the same number.

Cited by issue rather than by RFC number, because the upstream sequence is being
renumbered chronologically — #17 was never numbered — and an issue number never
changes.

Renumbering into the same sequence moves the collision rather than removing it,
because two authorities allocating from one counter is what produced it. A number
in that namespace is allocated upstream when a document is filed, and none of
these has been. Taking one early would mean two counters again.

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
- The effect algebra says what a row is, so the conflict rule is derived rather
  than stipulated.
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

The extension documents have been brought onto that surface. Where a document
quotes the language as it is today — the reproductions in the spec-surface and
effect-rows documents — it keeps the current spelling, because showing the
language as it actually is is the point of a reproduction.
