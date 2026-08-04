# Contributing

## Two enforcement regimes, kept apart

Most friction in agent-assisted repositories comes from conflating two things
that are not the same:

| | CI enforcement | authoring-time enforcement |
|---|---|---|
| runs on | the merge candidate | one contributor's editing loop |
| posture | adversarial | formative |
| harness | must be agnostic | inherently specific |
| blocks merge | yes | no |
| bears trust | yes | never |

The rule:

> Anything a trust claim depends on must be CI-enforced and harness-agnostic.
> Authoring-time tooling may exist, may be opinionated, and may be the project
> default. It may not be cited as the reason a property holds.

This repository can be opinionated about which authoring-time tools it supports
and ships defaults for. That is a separate question from what determines trust,
and keeping the two apart is what lets someone contribute from a different setup,
or none.

### Why this is a rule and not a preference

The failure mode is documented. In the upstream Thermite repository, two
agent-facing gates were implemented as editor hooks in a tracked but
machine-authored config file. A routine tool re-run removed them. They were
dormant for an entire development stage while the README, the design docs, and
four agent definitions continued to assert that they fired.

The enforcement claim was attached to a mechanism that could disappear without a
signal, and that no contributor on a different harness would have had.

## The targets

Every trust-bearing check is a `make` target and runs in CI. A contributor with
no agent tooling satisfies every requirement by running these:

| target | what it establishes |
|---|---|
| `make check-fork` | every forked file matches the [upstream pin](docs/upstream-pin.md), or is a listed divergence with a reason |
| `make image` | the image builds from this tree through `forge` at the pin |
| `make verify` | the receipt's bindings re-check against current source |
| `make determinism` | two independent builds on this host are byte-identical |
| `make image-container` | the image builds through the digest-pinned toolchain, so its bytes do not depend on the host |
| `make boot-matrix` | 1/2/4/8 CPUs, AP-start-failure, and reboot all boot under QEMU/OVMF |
| `make check` | all of the above |

## Practical consequences

- Every trust-bearing check is a target in the build file and runs in CI.
- Editor hooks and agent harness config, where present, shell out to those
  targets rather than reimplementing them.
- A contributor running no agent tooling satisfies every requirement by running
  the build targets.
- A check that cannot be expressed as a CI target is advice rather than a
  requirement, and goes in a document rather than a gate.

## Claims discipline

From [the assurance model](docs/assurance-model.md):

> Any assurance statement in this repository must be reducible to a set of
> per-clause tuples with named boundaries. A prose summary that cannot be
> expanded into tuples is not a claim.

Applies to the README, release notes, commit messages, and anything said about
the project elsewhere.

## Status vocabulary

Requirements are binary:

- **SHIPPED**: end-to-end functional, with a non-test consumer, tests, and
  verification evidence. Cite the symbol and the test.
- **NOT STARTED**: with a concrete open prerequisite named.

There is no "in progress", "partial", or "mostly done". Those are where
overclaiming lives, since they let architecture be reported as achievement. Work
underway belongs in the process log described below, rather than the status
table.

These two labels are vocabulary rather than emphasis. A [tone
pass](docs/tone-and-voice.md) does not soften them into a hedge or introduce a
third category by wording.

## Process and memory tooling

The project tracks work with [`day`](https://github.com/kan-tools/day) (process:
teloi, atoms, bridges) over [`kan`](https://github.com/kan-tools/kan) (append-only
signed memory). Both are pre-release, so the version flag is mandatory:

```bash
cargo install kan --version 0.9.1-beta.1
cargo install day --version 0.9.0-beta.1
day doctor          # prints the supported kan range against the kan you have
```

The versions matter, and the failure they prevent is silent. A bare
`cargo install kan` selects a release `day` was never measured against; `day
doctor` prints the range alongside the kan you have, and is the check to run.

Above its measured range `day` warns rather than refusing, on the grounds that
kan's read surface is additive. Observed here: `day` 0.9.0-beta.1 against kan
0.9.2-beta.1 warns, and `assess`, `bridge check` and `doctor` all work. Treat
that as tolerated rather than supported — the version above is the one this
repository's process log was written with.

This is authoring-time tooling under the rule above. It structures how work
proceeds and is not a trust-bearing gate. A contributor who does not use it can
still land changes; they will not have the process log.

`.claude/settings.json` wires `day hook session-start`, so the teloi, their
tensions, and the project's practice claims are injected at the top of an agent
session. The standard in [docs/tone-and-voice.md](docs/tone-and-voice.md) is
carried that way: its short form lives on the `practice` subject in kan and is
projected into every session.

To add or revise a practice claim:

```bash
kan observe "<the practice, under ~280 characters>" --subject practice
kan retract <cid>          # to withdraw one
kan publish practice       # to share it in .claims/
```

Claims longer than about 280 characters are truncated in the injected block, so
keep each one to a single point and put the full argument in a document.

Nothing here blocks a merge. The hook prints advisory context and does not fail a
build, which keeps it on the authoring-time side of the split.
