# Full words: a syntax-only change

**The anchor of [Thermite 3](thermite-3.md).** Kind: rename and reorder. It adds
no expressive power, no obligation, no type, and no metatheory. Every existing
program keeps its meaning, and every one of them changes.

This is the whole proposal. The reasoning behind the wider surface it anchors is
in [the surface conventions](surface-conventions.md); nothing from there is being
proposed here.

## The change

| from | to |
|---|---|
| `req P` | `requires P` |
| `ens P` | `ensures P` |
| `inv P` | `keeps P` |
| `dec E` | `measures E` |
| `fx E` (last) | `! E` (first, own line) |

Plus three things that follow from those:

**Clause order becomes** the effect row, then the bare clauses, then `measures`
last. Today it is `req` ×1, `ens` ×1+, `fx` ×1, then an optional `dec` — the row
is not last, and a recursive function carries its measure after it.

**A clause body may be a block of conjuncts**, with the bare single-expression
form as sugar:

```thermite
requires {
  cpu < 64;
  (s.expected >> cpu) & 1 == 1;
}
```

**`requires nothing`** is sugar for `requires true`.

That is the entire proposal.

## Why

Thermite is designed to be written mostly by language models, which makes
**semantic overlap with pretraining worth more than token economy**.

The failure mode of abbreviation is not that a model cannot learn it. It is that
abbreviations **actively misdirect**: `fx` reads as audio/visual effects, `dec` as
declare/decimal/decrement, `inv` as inverse or inventory. Those are wrong priors,
not absent ones. In a language where a misread clause yields a *vacuous proof*
rather than a compile error, that is a safety property rather than an ergonomic
one.

**The evidence is already paid.** A `guar`/`ens` collision consumed several
design cycles in a proposal for this language, and it happened *because both were
abbreviated*. `guarantees` and `ensures` do not collide. The abbreviation
destroyed the information that would have prevented the clash.

Note that the current spelling is a departure from **both** parents. Verus uses
full words, heavily — `ensures` 804, `requires` 465, `decreases` 161, `invariant`
117 in vstd. Rust is mixed, abbreviating only its most ubiquitous tokens: `fn`,
`mut`, `pub`. `req`/`ens`/`fx`/`inv`/`dec` is neither.

The counter-argument, that idiosyncrasy makes fine-tuning more specifying, is
real. It is judged to lose against the loss of semantic overlap.

## Why these particular words

`requires` and `ensures` are Verus's, and need no defence.

`keeps` and `measures` are not, so they do:

> **Every clause is a third-person-singular verb whose subject is the item.** A
> clause is a sentence with the subject elided, and the item supplies it.

```
f          requires  n < 100
f          ensures   result == n * 2
f          measures  p.count
the loop   keeps     acked & !expected == 0
Grant      keeps     base + len <= MAX_PHYS
```

`requires` and `ensures` already obey this. `inv` is a **noun in a verb slot**,
which is why it never sat right beside them, and `dec` names the expression's
property rather than the clause's purpose.

`measures` also fixes a mechanical problem. A clause keyword is a
semantic-address segment, and `validate_segments` matches a fixed allowlist after
splitting on `.`. So a clause keyword must be **one word** — a two-word spelling
is rejected as malformed before any lookup:

```
double.ens              → no such address     (segment well-formed)
double.terminates by    → malformed address   (rejected before lookup)
```

Each renamed clause needs its segment renamed in that allowlist. One line each.

## Why the row moves

`fx E` is a noun phrase sitting among verb phrases, and it is not a claim about
behaviour. It is part of the type: `() ! pure` and `() ! write(shootdown)` are
different types to the prover, so the row belongs to the arrow. `!` follows
Koka's `-> B ! e`.

```thermite
fn allocate(pages: u64) -> Result<Grant, u64>
  ! write(heap)
  requires  pages > 0 && pages <= 1024
  ensures   ...
```

Placing it first, on its own line between the signature and the predicates, makes
it read as type-level rather than predicate-level.

## Migration

**Every clause site in the corpus changes.** Measured across the 69 `.th` files
at `84d276e7`:

| | sites |
|---|---|
| `ens` | 208 |
| `req` | 160 |
| `fx` | 150 |
| `dec` | 31 |
| `inv` | 18 |
| **total** | **567**, across 155 items |
| `req true` | 108 |

Three things make that affordable.

**It is mechanical, and the tool exists.** `thermite-migrate.py` is a
source-to-source rewrite rather than a parse-and-print, so comments, blank lines
and expression text survive untouched — a formatter would produce a diff nobody
can review, and this change does not need one. A clause runs from its keyword
until its expression closes, tracked by delimiter balance, so a clause whose
expression wraps across lines moves as one unit.

**And it is proved information-preserving rather than argued to be.** The tool
rewrites in both directions, so the claim is checkable before any parser accepts
the new surface:

```
$ thermite-migrate.py --check conformance examples
round-trip: 67/67 files restore byte for byte
```

`to_v2(to_v3(x)) == x` for every file in the corpus, including the 24 clauses
whose expressions wrap. That is a stronger check than re-certifying, which cannot
be run at all until the front end changes.

Two facts the round-trip forced into the open, both of which a diff-by-eye would
have missed. The gap between a keyword and its expression is preserved verbatim
rather than re-aligned, because column-preserving arithmetic is not invertible
once it clamps — alignment is a formatter's job. And `fx` is **not last** in the
current grammar: a recursive function's `dec` follows it, so the row must be
restored before the measure rather than at the end.

**The one non-mechanical part is optional.** A naive rewriter emits
`requires true` rather than `requires nothing`. That stays legal — `true` remains
legal inside expressions and the sugar is clause-level only — so adopting it is a
second pass over 108 sites rather than a correctness condition.

**Certificates survive**, and this was checked rather than assumed. The
`.cert.json` oracle subset is `item` / `level` / `tautology` /
`vacuous_precondition` / `effects` / `slag`. Clause names appear nowhere in it, so
no oracle is invalidated and the migration is source-only.

## What is not in this proposal

Everything that would add capability, and it is a long list precisely so that
this one can be short:

```
survives · interleaves { asks / promises } · resource · forget / forgets(r)
opaque · by unfold(…) · shared declarations and checked effect rows
lock / owns / holding · protocol types · ensures on spec fn · blocks · cost(E)
handlers { } · the effect algebra
```

Each of those adds an obligation, a type, or a check, and each is a separate
proposal that assumes this one.

**Two abbreviations are deliberately left alone.** `alloc` and `rand` are
abbreviations that the principle above would rename. They are untouched here
because a later proposal turns them into `write(heap)` and `write(entropy)`
anyway, and renaming the same token twice is churn. Flagged so it reads as a
decision rather than an oversight.

## Implementing it

[A measured work plan](anchor-implementation.md) scopes it against the tree: the
compiler change is five keyword entries, five token variants, one ordering
change in `parse_contract`, and two lines in the address allowlist. The volume is
elsewhere — 619 clause lines embedded in 66 Rust test files, which the migration
tool does not reach because they live inside string literals.

The migration and the parser change are **one PR rather than two**, because no
front end accepts the new surface until the parser moves, so a migrated corpus
cannot certify on its own.

## What it asks

A review and a CI run. The corpus certifies before and after, the migration is a
tool rather than a hand edit, and no proof obligation anywhere changes.

It is also a **version-number event**, which makes it a concrete test case for
[#120](https://github.com/dollspace-gay/Thermite/issues/120), "Versioning — what
a Thermite version number promises": a breaking change to every source file, with
an automated migration, and no change to what any program proves.
