# Implementing the anchor

A work plan for [full words](full-words-anchor.md), scoped against the tree at
`84d276e7` rather than estimated. Every count below is measured.

This is Bulla's reading of someone else's codebase, so treat the site lists as a
starting map rather than a specification.

## The shape of it

The anchor is a rename and a reposition, so almost all of the work is in one
place and almost all of the *volume* is in another:

| | measured |
|---|---|
| lexer keyword entries | **5** |
| `TokKind` variants | **5** |
| references to those variants across the workspace | **53** |
| address-allowlist lines | **2** |
| clause names appearing as error strings | several, in `parser.rs` |
| `.th` corpus files | **67** — `git ls-files '*.th'` at the pin |
| Rust files carrying `.th` fragments that parse | **111**, carrying **1,527** clause sites |
| address strings to rename (`ens#k` → `ensures#k`) | **114**, across 27 files |
| clause words in doc-comment prose | 2,149 — judgement, not mechanism |
| golden/oracle directories | 22 |
| design docs mentioning the clauses | 52 |

**The compiler change is small and the test corpus is the schedule.** The number
to plan around is 1,527 clause sites inside Rust string literals, against 547 in
the `.th` corpus itself: three quarters of the migration is in the test suite.

A first count lumped three different treatments together and overstated the
mechanical work. They are distinct:

| | treatment |
|---|---|
| `.th` source in string literals | the string-literal variant of the migration tool |
| address strings, `ens#k` | a rename, alongside the allowlist |
| doc-comment prose | nothing mechanical — `∀ params, req → ⋀ ens` is dated after a rename, not wrong |

## The pieces

### 1. Lexer — small, and the ambiguity question is settled

`keyword_kind` (`thermite-syntax/src/lexer.rs:217`) maps five words to five
`TokKind` variants. Rename the words; the variants keep their names, so the 53
downstream references do not move.

`!` already lexes as `TokKind::Bang` (`:188`, `:896`), so the effect row needs a
parser production rather than a new token.

**The row is unambiguous by position**, checked rather than assumed. Migrating
the whole corpus and scanning every line gives **142 lines opening with a row and
zero lines opening with `!` that are not one**. The other three of the lexer's
145 `fx` tokens are accounted for: one inline row in `conformance/review/vacuous.th`,
and two in `conformance/parse/recover_per_item.th`, which does not parse by design. The three clause expressions that start with a
negation — `ens !result || p.count > 0` and friends — are unaffected, because the
`!` follows a keyword and never opens a line.

### 2. Parser — the ordering change

`parse_contract` (`parser.rs:1420`) is a straight-line state machine: exactly one
`req`, one or more `ens`, exactly one `fx`. Three changes:

- accept the row **first**, before `requires`
- accept one or more `requires`, to match `ensures`
- move `measures` to last

**Correcting a claim in the RFC's own history:** `fx` is *not* last today. A
recursive function carries `dec` after it — `examples/editor/editor.th` reads
`ens … fx pure … dec end - i`. The new order puts `measures` last, so this is a
genuine move rather than a no-op.

Error variants carry clause names as strings (`clause: "req".to_string()` and
friends). Those are user-facing text and want renaming with the keywords, or the
diagnostics will name tokens that no longer exist.

### 3. Conjunct blocks

`requires { a; b; }` is new syntax rather than a rename, and it is the only part
of the anchor that adds a production. It desugars to repeated clauses, so nothing
downstream of the AST needs to know about it — which is the argument for it being
in the anchor at all.

### 4. Addresses — two lines

`validate_segments` (`address.rs:331`, `:347`) matches a fixed allowlist:

```rust
if matches!(seg, "dec" | "proof" | "ens" | "req" | "inv") {
if !matches!(word, "loop" | "inv" | "ens" | "req") || !all_digits(num) {
```

Rename in place. This is also *why* a clause keyword must be a single word: a
space-bearing segment is rejected as malformed before any lookup.

### 5. The corpus — mechanical

```
$ thermite-migrate.py --write conformance examples src
```

Proved information-preserving by round-trip on all 67 `.th` files, including the 24
whose clause expressions wrap across lines.

### 6. The embedded test corpus — the actual work

1,527 clause sites inside 111 Rust files. The heaviest are conformance suites:

```
45  forge/tests/operators_conformance.rs
34  forge/tests/ergonomics_conformance.rs
33  forge/tests/string_search_conformance.rs
33  forge/tests/divergence_solver_vacuity.rs
30  forge/tests/mutual_recursion_conformance.rs
```

These are `.th` fragments in string literals, and **the tool now handles them**:

```
$ thermite-migrate.py --check --rust .
round-trip: 382/382 files restore byte for byte
clause-bearing literals with no effect row, left for review: 516
```

It rewrites a literal only when the literal declares an item, carries an effect
row, and round-trips reversibly on its own. The row is what distinguishes a
Thermite fragment from *expected lowered Verus*, which also declares items and,
after the rename, uses the same clause words. The 516 it declines are for review
rather than silent rewriting; most are expected output and prose, and some are
genuine `struct … inv` fragments with no `fn` to carry a row.

`forge/src/relax.rs` was flagged here as worth checking first, on the theory that
being source rather than tests it might *generate* clause text. It does not. Its
hits are doc-comment semantics (`∀ params, req → ⋀ ens`) and diagnostics naming
semantic addresses (`` `ens#{k}` is out of fragment ``), so it belongs in the
rename bucket rather than the rewrite one.

## Order to do it in

1. **Corpus first**, with the migration tool, on a branch that does not build.
   This is reversible and it makes the rest reviewable.
2. **Lexer and parser**, until the migrated corpus certifies.
3. **Addresses**, which is two lines and has its own tests.
4. **Embedded test corpus**, with the string-literal variant of the tool.
5. **Goldens**, regenerated rather than edited.
6. **Design docs**, last, since they are prose and drift is caught by the
   existing tripwire.

Steps 1 and 2 are the change. Steps 4 through 6 are the volume.

## Spiked, and what it showed

Steps 1 and 2 were built as a throwaway branch to test the plan against reality
rather than leave it as an estimate.

**The front-end change is 63 insertions and 62 deletions across five files** in
`thermite-syntax` — lexer, parser, addresses, AST and lib. Four keyword renames;
`fx` removed as a keyword entirely, since the row is `!` and `Bang` already
lexed; the row moved to the head of `parse_contract`; clause names in diagnostics
renamed to match.

**And the migrated corpus certifies identically.** This is the check the
round-trip explicitly cannot make:

| file | baseline v2 | migrated v3 |
|---|---|---|
| `parse_u64.th` | 1 at L3 | 1 at L3 |
| `list_sum.th` | 2 at L3 | 2 at L3 |
| `option_result.th` | 5 at L3 | 5 at L3 |
| `multi_adt.th` | 5 at L3 | 5 at L3 |
| `map_kv.th` | 1 at L3 | 1 at L3 |
| `bytes_eq_demo.th` | 4 at L3 | 4 at L3 |

Eighteen items, same levels. The rename preserves meaning to the prover and not
only information in the text.

## What is still undone

The spike is a spike. Three things remain before this is landable.

**Inline contracts are handled, and the route changed.** A whole contract on one
line —

```thermite
fn id(x: u32) -> u32 req true ens result == x fx pure { x }
```

— defeated two attempts at a text rewriter, and the decisive reason was that the
last clause's text runs to end of line and therefore contains the body, so moving
the row drags `{ x }` with it. Knowing where a contract ends and a body begins is
parsing rather than matching.

The plan recorded here was two passes: reflow each contract onto separate lines,
then run the existing line-start migration unaltered. Probing that showed the
reflow still has to locate the same boundary, so it moved the problem rather than
avoiding it. **The route is the front end.** A rewriter linking `thermite-syntax`
takes item boundaries from `parse` and every offset from `tokenize`, then splices
at spans. Two grammar facts make it exact: a clause keyword is a reserved token,
so `TokKind::Req` is a clause and an identifier spelled `req` is not; and
`parse_effect_row` is a closed grammar with no brace in it, so the row ends at the
first token that cannot continue it and the body's `{` is whatever follows.

Four traps recorded against the text approach dissolve rather than being solved.
Whitespace reassembly stops being a category, because nothing outside a spliced
span is touched. `-> !` in emitted Rust cannot be mistaken for a row, because
emitted Rust does not parse as Thermite. `@bv` tags are tokens. And the boundary
is the parser's answer rather than a heuristic.

Measured on a `git archive` export of the pin: 66 of 67 `.th` files migrate with
no clause keyword surviving, the decline being `conformance/parse/recover_per_item.th`,
whose purpose is to not parse; and 450 Rust literals migrate, with 43 declined
that carry clause keywords — `format!` templates, assertion prose, and fixtures
invalid on purpose.

**Conjunct blocks**, **`requires nothing`**, and **one-or-more `requires`** are
in the anchor and not in the spike. They add productions rather than rename
tokens, so they are the part that is genuinely new.

**The check changes with the route.** A round-trip proves information
preservation and is silent about coverage: it hid every inline contract and 17
`@bv`-tagged clauses across 10 files, because text a tool never touches is
restored perfectly. Parsing both sides and comparing ASTs is the replacement, and
it checks meaning rather than text.
