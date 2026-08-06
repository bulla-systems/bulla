# Thermite 3

The sequencing document for this directory. What the generation is, what order
its pieces land in, and which single change anchors the rest.

**Status: provisional, and ours.** Nothing here has been proposed upstream.

## The name is borrowed, not invented

Upstream already numbers generations:
[RFC-1](https://github.com/dollspace-gay/Thermite/issues/2), "Thermite 2 — a
dependent-type tier, a stratified cage, and new ladder boundaries." So there is a
convention for a generational proposal and this follows it rather than coining
one.

**Thermite 3 is a surface generation, not a semantics one.** Thermite 2 changed
what the language can prove. This changes what it reads like, and then adds
capability on top of the settled surface. That distinction is what makes the
sequence below work: the expensive-to-review part and the cheap-to-review part
are separable, and the cheap one goes first.

## The throughline

One principle, stated once, that every document here inherits:

> Thermite is written principally by language models, so **semantic overlap with
> pretraining is worth more than token economy** — and abbreviations do not merely
> fail to help, they misdirect. In a language where a misread clause yields a
> vacuous proof rather than a compile error, that is a safety property.

Three rules follow, and between them they decided every name in the set:

1. **Full words**, except where a symbol *is* the concept.
2. **Every clause is a third-person-singular verb whose subject is the item**, so
   a clause reads as a sentence with the subject elided.
3. **A thing that is not a claim about behaviour is not a clause.** The effect row
   belongs to the arrow; modifiers are adjectives on an item.

## The anchor: a syntax-only change

Written out as its own proposal in [full words](full-words-anchor.md), which is
the document to hand someone. This section is the summary.

The first proposal changes **no expressive power whatsoever**. Every existing
program keeps its meaning, and every one of them changes.

| in the anchor | why it is not a feature |
|---|---|
| `req` → `requires`, `ens` → `ensures` | rename |
| `inv` → `keeps`, `dec` → `measures` | rename |
| `fx <row>` → `! <row>`, own line, moved first | rename plus reposition |
| clause order: row, bare clauses, blocks, `measures` last | reorder |
| `requires { a; b; }` conjunct blocks | sugar for `&&`; also makes `requires` one-or-more like `ensures`, which `&&` already expresses |
| `requires nothing` | sugar for `true`, which stays legal in expressions |

**Not in the anchor**, because each adds an obligation, a type, or a check:

```
survives · interleaves { asks / promises } · resource / forget / forgets(r)
opaque + by unfold(…) · shared declarations and checked rows
lock / owns / holding · protocol / provides-role paths · ensures on spec fn
blocks · cost(E) · handlers { }
```

**One deliberate exception.** `alloc` and `rand` are abbreviations, so rule 1 says
rename them. The anchor leaves them alone, because
[verified effect rows](verified-effect-rows.md) turns them into `write(heap)` and
`write(entropy)` anyway, and renaming the same token twice is churn a maintainer
will notice. Flagged here so it reads as a decision rather than an oversight.

### Why this is the right first thing

**It is separately evaluable.** A maintainer can accept "your clause names are
better" without evaluating six feature proposals, and it is the cheapest possible
yes: no semantics change, no new obligations, no metatheory.

**It anchors everything after it.** Each later proposal is then written *in* the
settled surface rather than re-arguing naming inside a feature discussion.

**It is the highest-value-per-risk item.** If it lands, the throughline is
established. If it is rejected, we learn that early and cheaply, before investing
in six feature proposals in a surface upstream will not take.

**It is mechanical.** 567 clause sites across 69 files and 155 items, and a
rename plus a fixed reorder is a deterministic source-to-source rewrite — the
migration tool is a parser and a printer rather than an analysis. Certificates
survive, checked rather than assumed: clause names appear nowhere in the
`.cert.json` oracle subset.
[The migration section](surface-conventions.md#migration) carries the numbers.

**It is a version-number event**, which connects it to a live upstream question:
[RFC-3](https://github.com/dollspace-gay/Thermite/issues/120), "Versioning — what
a Thermite version number promises." A breaking syntax-only change with an
automated migration is close to the best possible test case for whatever that
answers.

## The sequence

```
1. defects                    issues, with reproductions — earns the standing
2. the RFC process            creates the vehicle; without it there is nowhere to file
3. the anchor                 syntax only, no new power — full-words-anchor.md
4. the effect algebra         what a row is; underpins 5
5. verified effect rows       rung 3, the multiplier
6. shared-state invariants    rung 4
7. resource types             rung 5, the honest goal
8. interference clauses       rung 6
9. protocol types             rung 7
```

Defects go first because they are a contribution rather than a request, and
because a project with no verified subsystem proposing a wholesale surface change
to someone else's language should arrive having already been useful.

The RFC process goes second because Thermite's only RFC namespace is its issue
tracker, which cannot version a document. Proposing a language change there means
posting a proposal into a system that models reports.

### Readiness

| document | state |
|---|---|
| [structured spec surface](structured-spec-surface.md) | **ready** — as issues, not an RFC |
| [surface conventions](surface-conventions.md) | **ready** — migration was the last hole |
| [the effect algebra](effect-algebra.md) | **ready** |
| [verified effect rows](verified-effect-rows.md) | **ready** — migration, kernel break and cert impact all stated |
| [shared-state invariants](shared-state-invariants.md) | **ready** — lock scope, the one-lock default, and the masking rule settled |
| [resource types](resource-types.md) | **ready** — contagion, `forget`, and `panic` settled |
| [interference clauses](interference-clauses.md) | **ready** — the lowering hypothesis is discharged, with the stability gap recorded |
| [protocol types](protocol-types.md) | ready as a document; depends on resource types landing |
| [the crash clause](crash-clause.md) | **not ready** — parked for a Bulla reason that does not transfer, and the crash model is the real blocker |

### Dependencies between them

```
effect algebra ──→ verified effect rows ──→ shared-state invariants ──→ interference clauses
                                                  │                            │
resource types ───────────────────────────────────┴──→ protocol types ─────────┘
```

Protocols need resources, because an endpoint that can be dropped abandons its
peer mid-session. Interference needs both the row and the lock discipline,
because its whole claim is that it is the cheaper option where those two are too
strong.

## What is not in this generation

The research rungs, which are on [the ladder](../the-ladder.md#the-rungs) rather
than in this sequence: noninterference, cost as a discharged effect, an algebra
for composing certificates, and distributional effects. Each has a reachable
surface and an open discharge, which is what makes them research rather than
work.

Also out: user-supplied effect equations and effect handlers in the Koka sense.
The [effect algebra](effect-algebra.md#what-is-deferred-and-to-where) records
where those sit and why a fixed basis with user combinations is the tractable
part.

## What this asks of a maintainer

Read in order, the ask is small and gets larger:

1. Four defect reports with reproductions. Costs a triage.
2. A process proposal that migrates their three existing RFCs and adds a
   front-matter field feeding the REQ registry they already built. Costs a review.
3. A rename with a migration tool and a corpus that still certifies. Costs a
   review and a CI run.

Nothing after that is proposed until those three land, because a surface nobody
adopted is not a foundation to build six proposals on.
