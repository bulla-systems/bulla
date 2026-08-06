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

## An argument the migration turned up

After the rename, Thermite's `requires` and Verus's `requires` are the same word,
so **lowering becomes identity rather than translation** for four of the five
clauses. Emitted Verus reads against its Thermite source directly, and a reader
comparing the two no longer has to hold a mapping in their head.

That was not why the change was proposed, and it is a real argument for it. It
surfaced because a text tool cannot tell a Thermite fragment from an *expected
lowered-output* fragment by vocabulary once the two vocabularies agree — which is
a cost for the migration and a benefit for everyone reading the output
afterwards.

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

**Every clause site in the corpus changes.** Counted by the pinned lexer across
the 67 `.th` files tracked at `84d276e7` — a `req` token is a clause and an
identifier spelled `req` is not, which is the distinction a textual count cannot
make:

| | sites |
|---|---|
| `ens` | 205 |
| `req` | 152 |
| `fx` | 145 |
| `dec` | 26 |
| `inv` | 19 |
| **total** | **547**, across 144 contracts |
| `req true` | 100 |
| `ens true` | 2 |

> **Corrected 2026-08-06.** This table previously read 208/160/150/31/18, 567
> across 155 items, over "the 69 `.th` files". The corpus is **67** files:
> `git ls-files '*.th'` at the pin. The 69 counted `src/context.th` and
> `src/p.th` — Bulla's own probe files, left in the build clone when the count
> was taken — as part of Thermite's corpus, and they carry 19 clause sites
> between them. The figures above are the lexer's, on a `git archive` export of
> the pin, so they are reproducible with one command and carry no probe residue.

Three things make that affordable.

**It is mechanical.** A rename plus a fixed reorder is a deterministic
source-to-source rewrite: nothing about it depends on what a program means. The
migration edits spans rather than reprinting files, so comments, blank lines,
expression text and alignment survive untouched. A formatter would produce a diff
nobody can review, and this change does not need one.

**The front end drives it, so the hard case is exact.** The hard case is a
contract written on one line, which is most of the test corpus:

```thermite
fn id(x: u32) -> u32 req true ens result == x fx pure { x }
```

Moving the row to the front means knowing where the contract ends and the body
begins, and that is parsing rather than matching. A rewriter linking
`thermite-syntax` takes item boundaries from `parse` and every offset from
`tokenize`; two facts from the grammar then settle it. A clause keyword is a
reserved token, so `TokKind::Req` is a clause and an identifier spelled `req`
cannot be one. And `parse_effect_row` is a closed grammar containing no brace, so
the row ends at the first token that cannot continue it and the body's `{` is
whatever follows.

Measured on a `git archive` export of the pin:

| | |
|---|---|
| `.th` corpus | **66 of 67 migrate**, with no clause keyword surviving |
| the one decline | `conformance/parse/recover_per_item.th`, whose purpose is to not parse |
| `.th` fragments in Rust literals | **450 migrate**, carrying 1,527 clause sites across 111 files |
| declined, carrying no clause keyword | 340, where declining costs nothing |
| declined and clause-bearing | **43**: `format!` templates, assertion prose, and fixtures that are invalid on purpose |

Parsing both sides and comparing ASTs is then available as the migration's
check, which is meaning preservation rather than the textual kind.

**What a text-matching tool could not check, recorded because it generalises.**
An earlier rewriter matched a clause keyword at the head of a line and proved
itself by round-trip — `to_v2(to_v3(x)) == x`, byte for byte, on 382 of 382
files. That check is silent about text a tool never touches, because untouched
text is restored perfectly, and the silence hid two things: every one-line
contract, and 17 `@bv`-tagged clauses across 10 files that the pattern did not
match. A migrated corpus would have carried `ens@bv64` into a front end with no
`ens` keyword. Reversibility is worth having and does not measure coverage.

It did force two facts into the open that a diff-by-eye would have missed. The
gap between a keyword and its expression is preserved verbatim rather than
re-aligned, because column-preserving arithmetic is not invertible once it
clamps. And `fx` is **not last** in the current grammar — a recursive function's
`dec` follows it — so the row moves out from the middle rather than off the end.

**The one non-mechanical part is optional.** A naive rewriter emits
`requires true` rather than `requires nothing`. That stays legal — `true` remains
legal inside expressions and the sugar is clause-level only — so adopting it is a
second pass over 100 sites rather than a correctness condition.

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
elsewhere: **1,527 clause sites live inside Rust string literals**, across 450
`.th` fragments in 111 test files, against 547 in the `.th` corpus itself. Three
quarters of the migration is in the test suite.

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
