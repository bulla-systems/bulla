# Contributing

## Two enforcement regimes, kept apart

Most friction in agent-assisted repositories comes from conflating two things
that are not the same:

| | **CI enforcement** | **authoring-time enforcement** |
|---|---|---|
| runs on | the merge candidate | one contributor's editing loop |
| posture | adversarial | formative |
| harness | **must be agnostic** | inherently specific |
| blocks merge | yes | no |
| bears trust | **yes** | never |

**The rule:**

> Anything load-bearing for a trust claim must be CI-enforced and
> harness-agnostic. Authoring-time tooling may exist, may be opinionated, and
> may be the project default — but it may **never** be cited as the reason a
> property holds.

This repository is free to be opinionated about which authoring-time tools it
supports and ships defaults for. That is a separate question from what
determines trust, and keeping them separate is what makes contribution possible
for someone running a different setup — or none.

### Why this is a rule and not a preference

The failure mode is documented. In the upstream Thermite repository, two
agent-facing gates were implemented as editor hooks in a tracked-but-
machine-authored config file. A routine tool re-run silently removed them. They
were dormant for an entire development stage while the README, the design docs,
and four agent definitions all continued asserting they fired.

Nobody lied. The enforcement claim was simply attached to a mechanism that could
disappear without any signal — and no contributor on a different harness would
have had it in the first place.

## Practical consequences

- Every trust-bearing check is a target in the build file and runs in CI.
- Editor hooks and agent harness config, if present, **shell out to those
  targets** rather than reimplementing them.
- A contributor running no agent tooling can satisfy every requirement by
  running the build targets.
- If a check cannot be expressed as a CI target, it is not a requirement. It is
  advice, and it goes in a document rather than a gate.

## Claims discipline

From [the assurance model](docs/assurance-model.md):

> Any assurance statement in this repository must be reducible to a set of
> per-clause tuples with named boundaries. A prose summary that cannot be
> expanded into tuples is not a claim; it is marketing.

Applies to the README, release notes, commit messages, and anything said about
the project elsewhere.

## Status vocabulary

Requirements are **binary**:

- **SHIPPED** — end-to-end functional, with a non-test consumer, tests, and
  verification evidence. Cite the symbol and the test.
- **NOT STARTED** — with a concrete open prerequisite named.

There is deliberately no "in progress," "partial," or "mostly done." Those are
where overclaiming lives: they let architecture be reported as achievement. Work
underway lives in the process log (see below), not in the status table.

## Process and memory tooling

The project tracks work with [`day`](https://github.com/kan-tools/day) (process:
teloi, atoms, bridges) over [`kan`](https://github.com/kan-tools/kan) (append-only
signed memory). Both are pre-release, so the version flag is mandatory:

```bash
cargo install kan --version <pre-release>
cargo install day --version <pre-release>
day doctor          # prints the supported kan range against the kan you have
```

This is **authoring-time tooling under the rule above** — it structures how work
proceeds and is not a trust-bearing gate. A contributor who does not use it can
still land changes; they just will not have the process log.
