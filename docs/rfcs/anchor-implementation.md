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
| `.th` corpus files | **65** — the migration tool rewrites these |
| Rust files embedding `.th` source in string literals | **114**, carrying **762** clause lines |
| address strings to rename (`ens#k` → `ensures#k`) | **114**, across 27 files |
| clause words in doc-comment prose | 2,149 — judgement, not mechanism |
| golden/oracle directories | 22 |
| design docs mentioning the clauses | 52 |

**The compiler change is small and the test corpus is the schedule.** The number
to plan around is 762 clause lines in string literals across 114 Rust files:
`thermite-migrate.py` does not reach them, because they are not `.th` files.

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
the whole corpus and scanning every line gives **144 row lines and zero other
lines beginning with `!`**. The three clause expressions that start with a
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

Proved information-preserving by round-trip on all 67 files, including the 24
whose clause expressions wrap across lines.

### 6. The embedded test corpus — the actual work

619 clause lines inside 66 Rust files. The heaviest are conformance suites:

```
45  forge/tests/operators_conformance.rs
34  forge/tests/ergonomics_conformance.rs
33  forge/tests/string_search_conformance.rs
33  forge/tests/divergence_solver_vacuity.rs
30  forge/tests/mutual_recursion_conformance.rs
```

These are `.th` fragments in string literals. A variant of the migration tool
that rewrites clause lines *inside* string literals handles them, and its
round-trip check applies unchanged — which is the argument for building that
rather than making 762 edits by hand.

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

## What this cannot tell you

Whether the corpus still *certifies* after migration. That needs steps 1 and 2
done together, because no front end accepts the new surface until the parser
moves — which is why the migration and the parser change are one PR rather than
two.

The round-trip proof establishes that the rewrite loses nothing. It does not
establish that the result means the same thing to the prover, and only
re-certifying does.
