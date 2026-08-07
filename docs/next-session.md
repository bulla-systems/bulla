# Bulla — continuing the Thermite 3 roadmap

## Get up to speed properly before doing anything

This is a large body of design work with a lot of settled detail, and most of the
mistakes available here are re-deriving something already decided or contradicting
a document. Do a real context dive first.

**Read, in order:**

1. `docs/rfcs/thermite-3.md` — the surface in full, each construct marked by when
   it lands. This is the specification and the roadmap in one document.
2. `docs/rfcs/full-words-anchor.md` — the syntax-only change that anchors
   everything. Filed as Thermite PR #128; this is the document under review.
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
below is in kan — 139 claims across `atom/language-probe`, `atom/rfc-draft`,
`atom/gap-report` and `practice`, all published to `.claims/`. Read the ones for
whatever you are about to touch; they carry the *why*, which the documents often
compress.

## Where the roadmap is

```
1. defects            FILED    Thermite #124, #125, #126
2. the RFC process    FILED    Thermite PR #127 — open, CI green
3. the anchor         FILED    Thermite PR #128 — open, CI green, stacked on #127
   the horizon        FILED    Thermite PR #129 — RFC-7, the whole surface, on #128
4–9. capability set   STAGED   RFC-8..14, written and gated, deliberately unfiled
```

**The Thermite 3 work has moved out of this repository.** It now lives in
[`maxinelevesque/Thermite3-staging`](https://github.com/maxinelevesque/Thermite3-staging),
a staging fork of Thermite with its own `day` and `kan`. Bulla keeps the design
record in `docs/rfcs/`; the staging fork is where the implementation happens and
where the RFCs are shaped for upstream.

| branch there | what |
|---|---|
| `main` | process layer, `tooling/thermite3-migrate` |
| `anchor/implementation` | RFC-6's front end, committed, both crates building |
| `rfcs/thermite-3-set` | RFC-8 … RFC-14, 19 requirements, gates green |

Its issues #1–#9 mirror the upstream bug reports, which stay open upstream and
canonical. `bridge/land-the-anchor` is the live path there.

The whole design set is also published as a site:
[maxine.science/thermite-3](https://maxine.science/thermite-3/), built from
[`maxinelevesque/thermite-3`](https://github.com/maxinelevesque/thermite-3).

### What is proved about the anchor, and it is filed

- **The front-end change is 63 insertions / 62 deletions across 5 files** in
  `thermite-syntax`. Saved as `tooling/migrate/anchor-front-end.patch`, applies
  clean at `84d276e`.
- **The migrated corpus certifies identically** — 18 items at L3 across 6 files,
  same levels and the same exit status as baseline, against Verus
  `0.2026.05.24.ecee80a`. Re-run this session with the AST rewriter rather than
  inherited from the spike. `map_kv.th` exits 1 in *both* directions, for an
  `ens true` that §7.1(a) rejects; reproducing that matters as much as the passes.
- **The migration reaches the whole corpus.** 66 of 67 `.th` files migrate with
  no clause keyword surviving, plus 450 embedded fragments carrying 1,527 clause
  sites across 111 Rust files.

### What is undone, and it is specific

- **Three new productions** in the anchor and not in the spike: conjunct blocks
  (`requires { a; b; }`), `requires nothing`, and one-or-more `requires`. These
  are the only genuinely new part; everything else is a rename or a move.
- **43 clause-bearing literals** the rewriter declines, now enumerated by
  `tooling/migrate/coverage.py` rather than counted. `format!` templates,
  assertion prose, and fixtures invalid on purpose. The RFC owes this list to the
  implementation PR.
- **A file with any parse error is declined whole.** `parse` recovers per item,
  so migrating the items that parsed would shrink the 43. The obvious refinement.
- **The Rust-literal write path is measured, not built.** `unescape.py` carries
  the offset map it needs.

### The inline-contract route changed, so do not follow the old one

The recorded plan was two passes: reflow each contract onto its own lines, then
run the line-start migration. Probing it showed the reflow still has to locate
the contract/body boundary, so it moves the problem rather than avoiding it.

**The route is the front end.** `tooling/migrate/thmig` links `thermite-syntax`:
`parse` gives item boundaries and decides whether text is Thermite at all,
`tokenize` gives every offset, and the rewrite splices at spans. A clause keyword
is a reserved token, and `parse_effect_row` is a closed grammar with no brace in
it, so the boundary is the parser's answer rather than a heuristic. It lives on
the local branch **`anchor/migrate-ast`**, unpushed, and needs `.build/thermite`
at the pin plus the non-default `bv` cargo feature.

`tooling/migrate/thermite-migrate.py` is the superseded text tool. It stays for
its round-trip, with its two measured gaps recorded in place.

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

## What is next *here*

Thermite 3 has its own repository now, so what remains in Bulla is Bulla's own
work: **T0, the execution-context subsystem**, which `docs/roadmap.md` calls the
whole near-term plan. It is designed fresh rather than ported — `src/context.th`
stays a probe and is not restarted.

It is gated on G4 and G12, **both being fixed upstream directly**. Those two are
one blocker rather than two: G4 means the kernel cannot be modelled, G12 means a
correct model still cannot be shown to meet the §7 floor, so fixing either alone
buys nothing demonstrable.

The design work does not wait on them. Architecture §5.3 settles that Bulla
designs the composed model and encodes it flat by a stated rule, and the flat
encoding certifies today.

## Open, and yours to decide

- **The capability RFCs are written and staged, not filed.** RFC-8 through RFC-14
  live in the staging fork with their requirements registered and every gate
  green, so nothing is blocked on a reply. They stay unfiled until the anchor
  lands. Filing them is a decision, not a next step.
- **Steps 4 through 9 are blocked by our own rule** for *filing*, not for work:
  `thermite-3.md` says nothing after the anchor is proposed until it lands,
  because a surface nobody adopted is not a foundation for six proposals. Six
  upstream items are open with no maintainer response. Filing a seventh is the
  wrong move; deciding to change the rule is a decision worth making explicitly.
- **Conjunct-block semantics** — desugaring to repeated clauses is assumed and
  unspecified.
- The **stability conjunct** in interference (`final(s).epoch == s.epoch`) does
  not map to persistent sharding. Recorded in `interference-clauses.md`; it is the
  one part of that lowering that is not settled.

## Blocked, not forgotten

**G4 (#122) and G12 are being fixed upstream directly, as of 2026-08-06. Do not
start on either.** They are also mirrored as staging issues #5 and #7.** Together they are the whole critical path
for Bulla having any verified evidence: G4 means the kernel cannot be modelled,
G12 means a correct model still cannot be shown to meet the §7 floor, so fixing
one without the other buys nothing demonstrable.

T0 waits on #122. `src/context.th` is retained as a probe certifying 8/13 items
including `create` at L3 — **do not restart the port**; the execution-context
subsystem gets designed fresh. Physical hardware boot is parked with its scoping
in `docs/roadmap.md`. G4 blocks resource contagion from being enforceable.

Gaps G6–G11, G13 and G14 are recorded and unfiled, per the sequencing note.

## Working state

`v0.1.1-alpha.2` on GHCR carries `e46c4060…`, pulled and booted on a machine that
did not build it. `make check` is green. Commit signing works — per-device key,
verified end to end.

## Environment, and it will bite

- **`verus` is not on PATH**, and the scratchpad is session-specific, so re-fetch
  it every time. This URL works and takes about a minute:

  ```
  curl -sL -o verus.zip https://github.com/verus-lang/verus/releases/download/\
  release%2F0.2026.05.24.ecee80a/verus-0.2026.05.24.ecee80a-arm64-macos.zip
  ```

  `macos_allow_gatekeeper.sh` **exits 1 when there is no quarantine attribute**,
  which is the normal case for a `curl`ed archive. That is benign: check
  `verus --version` exits 0 rather than trusting the script's status.
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
instead of a defect. And know its limits, which cost real work this session: a
round-trip scores what a tool *did* and never what it *skipped*. It reported
382/382 restoring byte for byte while failing to touch every one-line contract
and 17 `@bv`-tagged clauses. Pair reversibility with a completeness check — here,
one line asserting no v2 clause token survives migration.

**Measure a pinned upstream on a `git archive` export of the pin.** Counting
through `.build/thermite`, a clone this repository writes into, put two of Bulla's
own probe files into every published corpus figure: 69 files where there are 67,
567 clause sites where there are 547, 384/384 where it is 382/382. Count clause
sites with the lexer, not a regex, so a word in a comment cannot be a keyword.

**When a gate goes red, establish whose fault it is before fixing it.**
`doc-drift` failed on the RFC branch and looked pre-existing; running it on a
worktree at the branch point showed it exits 0 there, so the drift was ours.
Editing `registry.toml` drifts the design doc that governs it, and the fix is a
manual re-pin rather than a workaround.

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
