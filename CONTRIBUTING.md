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

## The targets

Every trust-bearing check is a `make` target and runs in CI. A contributor with
no agent tooling satisfies every requirement by running these:

| target | what it establishes |
|---|---|
| `make check-fork` | every forked file matches the [upstream pin](docs/upstream-pin.md), or is a listed divergence with a reason |
| `make image` | the image builds from this tree through `forge` at the pin |
| `make verify` | the receipt's bindings re-check against current source |
| `make determinism` | two independent builds are byte-identical |
| `make boot-matrix` | 1/2/4/8 CPUs, AP-start-failure, and reboot all boot under QEMU/OVMF |
| `make check` | all of the above |

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
cargo install kan --version 0.9.1-beta.1
cargo install day --version 0.9.0-beta.1
day doctor          # prints the supported kan range against the kan you have
```

The versions are load-bearing. `day` 0.9.0-beta.1 supports exactly `0.9.1..=0.9.1`
of kan; a bare `cargo install kan` picks a release outside that range and `day`
cannot talk to it. `day doctor` prints the range and what you have — run it.

This is **authoring-time tooling under the rule above** — it structures how work
proceeds and is not a trust-bearing gate. A contributor who does not use it can
still land changes; they just will not have the process log.
