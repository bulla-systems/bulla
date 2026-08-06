# Bulla — continuing the Thermite 3 roadmap

## Get up to speed properly before doing anything

This is a large body of design work with a lot of settled detail, and most of the
mistakes available here are re-deriving something already decided or contradicting
a document. Do a real context dive first.

**Read, in order:**

1. `docs/rfcs/thermite-3.md` — the surface in full, each construct marked by when
   it lands. This is the specification and the roadmap in one document.
2. `docs/rfcs/full-words-anchor.md` — the syntax-only change that anchors
   everything, and the next thing to propose.
3. `docs/rfcs/anchor-implementation.md` — the measured work plan, the spike
   result, and what is still undone.
4. `docs/rfcs/effect-algebra.md` — what an effect *is*: theories, the
   admissibility criterion, the basis.
5. `docs/rfcs/surface-conventions.md` — the design record behind the anchor, with
   every rejected candidate and why.
6. `docs/the-ladder.md`, `docs/architecture.md`, `docs/language-gaps.md`.
7. `docs/examples/thermite3-tour.th` — the whole proposed surface as one coherent
   subsystem. Open it in vim; syntax highlighting is installed.

**Then read the process log.** `day hook session-start` injects the teloi,
tensions and practice claims. Beyond that, the reasoning behind every decision
below is in kan — 123 claims across `atom/language-probe`, `atom/rfc-draft`,
`atom/gap-report` and `practice`, all published to `.claims/`. Read the ones for
whatever you are about to touch; they carry the *why*, which the documents often
compress.

## Where the roadmap is

```
1. defects            FILED    Thermite #124, #125, #126
2. the RFC process    FILED    Thermite PR #127 — open, CI green
3. the anchor         FILED    Thermite PR #128 — open, stacked on #127
4. the effect algebra ready  ← you are here
5. verified effect rows        rung 3, the multiplier
6. shared-state invariants     rung 4
7. resource types              rung 5, the honest goal
8. interference clauses        rung 6
9. protocol types              rung 7
```

### What is proved about the anchor

- **The front-end change is 63 insertions / 62 deletions across 5 files** in
  `thermite-syntax`. Saved as `tooling/migrate/anchor-front-end.patch`, applies
  at `84d276e`.
- **The migrated corpus certifies identically** — 18 items across 6 files, same
  L3 counts as baseline. That is the check the round-trip cannot make.
- **The migration tool round-trips 382/382 files byte for byte**
  (`tooling/migrate/thermite-migrate.py --check --rust .`).

### What is undone, and it is specific

- **Inline contracts** — `fn id(x: u32) -> u32 req true ens result == x fx pure { x }`,
  373 sites across 83 files. Attempted twice, backed out twice. The decisive
  reason: the last clause's text runs to end of line and therefore contains the
  function body, so moving the row drags `{ x }` with it. **The route is two
  passes** — reformat inline contracts onto separate lines first, then the
  existing line-start migration handles them unaltered. Read the comment block in
  the tool before starting; it lists all four traps.
- **Three new productions** in the anchor and not in the spike: conjunct blocks
  (`requires { a; b; }`), `requires nothing`, and one-or-more `requires`.
- **516 clause-bearing literals** the tool declines to touch, reported for human
  review. Mostly expected Verus output and prose.

## The settled surface, so you do not re-derive it

| | |
|---|---|
| linearity | `resource struct Grant` |
| termination | `measures M`, comma list for lexicographic |
| invariant | `keeps P` — before a loop's body brace, not inside it |
| crash | `survives P` |
| concurrency | `interleaves { asks …; promises …; }`, both mandatory |
| clause bodies | conjunct blocks, bare single expression as sugar |
| trivial | `nothing` everywhere; `anything` removed |
| effect row | `!` first; two families; `shared` named, `resource` not |
| locks | `lock N guards T [after M]`, `owns(r)` in the row, `holding r { }` required |
| protocols | `protocol P { User { … }, Provider { … }, end }`, endpoints `P::Role` |
| interrupts | `handlers { h at 1 }` — not an effect |
| abandonment | `forget(g)`, recorded as `forgets(r)` |

**The organising rule:** every clause is a third-person-singular verb whose
subject is the item. It decided the names; do not treat it as decoration.

## Open, and yours to decide

- **Whether to propose the anchor now or after the inline work.** It cannot land
  without inline handling, because the test suite will not pass.
- **Conjunct-block semantics** — desugaring to repeated clauses is assumed and
  unspecified.
- The **stability conjunct** in interference (`final(s).epoch == s.epoch`) does
  not map to persistent sharding. Recorded in `interference-clauses.md`; it is the
  one part of that lowering that is not settled.

## Blocked, not forgotten

T0 waits on Thermite#122. `src/context.th` is retained as a probe certifying 8/13
items including `create` at L3 — **do not restart the port**; the
execution-context subsystem gets designed fresh. Physical hardware boot is parked
with its scoping in `docs/roadmap.md`. G4 blocks resource contagion from being
enforceable.

Gaps G6–G11, G13 and G14 are recorded and unfiled, per the sequencing note.

## Working state

`v0.1.1-alpha.2` on GHCR carries `e46c4060…`, pulled and booted on a machine that
did not build it. `make check` is green. Commit signing works — per-device key,
verified end to end.

## Environment, and it will bite

- **`verus` is not on PATH.** It is required for every `forge check`. Last session
  fetched `0.2026.05.24.ecee80a` (arm64-macos) into the scratchpad, which is
  session-specific and now gone. Re-fetch it before probing, and run
  `macos_allow_gatekeeper.sh`.
- **`cadical` is absent**, so `EprSolverUnavailable` verdicts are a missing binary
  rather than a language failure.
- **Python here is 3.9**, so `tomllib` is unavailable and three upstream gates
  report *inconclusive* and exit 3. Use `uv run --python 3.11` for anything
  touching the REQ registry or doc-drift.
- **`.build/thermite` is the build clone**, managed by `scripts/build-image.sh`.
  Clone separately for upstream PR work.

## Discipline

**Probe before specifying.** A three-line file and a checker verdict, not a
reading of the reference. It contradicted the documentation in both directions
repeatedly, and it caught four wrong claims in our own most careful document.

**Verify exit codes directly.** `cmd | tail; echo $?` reports `tail`'s status.
That error reached a PR description last session and needed a public correction.

**Build the cheap reversible check first.** It turns wrong work into a revert
instead of a defect. And know its limits: a round-trip is silent about what a tool
*fails* to touch, and preserving information is not the same as preserving meaning
to the prover.

**SHIPPED with cited evidence, or NOT STARTED with a named blocker.** Prose
follows `docs/tone-and-voice.md`.

**File defects with reproductions.** PRs upstream are fine now — this repository
shares a maintainer with Thermite — but draft and show before pushing.

## The framing, which matters for every proposal

The motivation is Thermite's own stated purpose: it is designed to be written
principally by agents, and the surface does not yet serve that. A keyword's real
cost is the prior it activates rather than the tokens it spends. Bulla's role is
**discovery** — a workload chosen to press hard enough to find where the surface
and the capability run out. That buys evidence, not standing.
