# RFC-000 — Surface conventions

Cross-cutting. Every other RFC in this directory assumes these.

**Status: provisional, and ours.** Not proposed upstream. Breaking changes are
assumed acceptable — Thermite is early, and the clause set is about to roughly
double, so the cost of settling conventions is lowest now.

## The governing principle: written principally by agents

Thermite is designed to be written mostly by language models. That makes
**semantic overlap with pretraining** worth more than token economy.

The failure mode of abbreviation is not that a model cannot learn it. It is that
abbreviations **actively misdirect**: `fx` reads as audio/visual effects, `dec` as
declare/decimal/decrement, `inv` as inverse or inventory. Those are wrong priors,
not absent ones. In a language where a misread clause yields a *vacuous proof*
rather than a compile error, that is a safety property.

The counter-argument — that idiosyncrasy makes fine-tuning more specifying — is
real, and judged to lose against the loss of semantic overlap.

**Evidence already paid:** the `guar`/`ens` collision that consumed several
design cycles happened *because both were abbreviated*. `guarantees` and
`ensures` do not collide. The abbreviation destroyed exactly the information that
would have prevented the clash.

Note this is a departure from **both** parents. Verus uses full words
(`ensures` 804, `requires` 465, `decreases` 161, `invariant` 117 in vstd); Rust
is mixed, abbreviating only its most ubiquitous tokens (`fn`, `mut`, `pub`).
Thermite's `req`/`ens`/`fx`/`inv`/`dec` is neither.

## Words for concepts, symbols only where the symbol *is* the concept

| kept as a symbol | because |
|---|---|
| `->` function type | universal, unambiguous in position |
| `=>` match arm | universal |
| `\|x\|` closure | universal |
| `!` effect row | Koka's `-> B ! e`; type-level, not a predicate |
| operators | ordinary |

Everything else is a word. Symbol space is small and adversarial; word space is
not, so **adding a concept means adding a word rather than inventing a glyph and
hoping it does not collide.**

This principle retired two earlier proposals: `<~`/`~>` for interference, and
`->`/`<-` for protocol direction. Both were glyphs invented to dodge a collision
that abbreviation had caused.

## Clause vocabulary

```
on fn        requires  ensures  concurrent { asks  promises }  crash
on struct    invariant
on spec fn   <termination measure>   ensures
on loop      invariant  <termination measure>
type-level   ! <effect row>
modifiers    opaque  <linearity>
```

Ordering, mandatory as the language already requires: signature, effect row,
`requires`, `concurrent`, `ensures`, `crash`, then any proof hints.

## Decisions

### Effects belong to the arrow, not the predicates

`effects E` was grammatically out of place — a noun phrase among verb phrases —
because it is not a claim about behaviour. It is part of the type.

```thermite
fn allocate(a: Allocator, pages: u64) -> Result<(Allocator, Grant), u64>
  ! write(memory), allocate
  requires  pages > 0 && pages <= 1024
  ensures   ...
```

Its own line, marked by a symbol, sitting between the signature and the
predicates — visually type-level rather than predicate-level. `! pure` reads
where `with pure` did not.

### Interference is grouped, not listed

`requires`/`ensures` are about *this* execution at its endpoints.
`asks`/`promises` are about *other* executions during it. Parallel but on a
different axis, and a flat list hides that.

```thermite
  requires  cpu < 64 && (s.expected >> cpu) & 1 == 1
  ensures   (final(s).acked >> cpu) & 1 == 1
  concurrent {
    asks      final(s).acked | s.acked == final(s).acked
    promises  final(s).acked == s.acked | (1 << cpu)
  }
```

The block does three jobs: names the axis, groups the pair, and marks the
function concurrent — so no `conc` effect atom is needed.

**The block is load-bearing, not decorative.** `requires`/`ensures` is *also*
ask-and-promise, to the caller rather than the environment; only the block
distinguishes the party. `asks` or `promises` appearing outside a
`concurrent { }` must be **a parse error, not a convention.**

(`concurrent { requires ... ensures ... }` would be technically workable, reusing
the same two words on a different axis. Distinct words were judged to help more
than the symmetry does.)

### Shared state is `shared`, not `region`

"Region" is effect-systems jargon that describes the mechanism. `shared` names
the safety-relevant property — that multiple things can reach it, which is why it
needs discipline.

```thermite
shared scheduler: SchedState
shared shootdown: Shoot
```

### Protocols name what an endpoint offers

`dual` is a mathematician's word for "the mirror of this"; `client`/`server`
bakes in a topology assumption; `Channel<send T>` misreads as "a channel you send
`T`s on" — a message type rather than a role.

```thermite
protocol PageRequest {
  provider sends { status: u32, base: u64 },
  user     sends { op: u32, count: u64 },
  end,
}

fn pager(c: provides PageRequest) -> () ! channel
fn app(c: uses PageRequest)       -> () ! channel
```

`provides` / `uses` reads as English, carries no topology assumption, and the
endpoint type stands alone — no `Channel<>` wrapper needed, because the endpoint
*is* the type.

**On effect ambiguity:** a channel endpoint arrives as a parameter, so its
identity is already in the signature. The effect row only needs to record the
*kind* of effect, which is why bare `! channel` suffices where global state needs
`! write(name)`. If endpoints were ever reachable from global state, that would
no longer hold.

### Opacity is discharged per obligation, not per function

An earlier `unfolds` clause was wrong because it is not a claim about behaviour —
it is a proof hint. But a *function-level* hint is also too coarse.

```thermite
fn build(regions: Vec<u64>) -> Result<Plan, u64>
  ! allocate
  requires  anything
  ensures   match result { Ok(p) => plan_ok(p), Err(e) => true }
            by unfold(plan_ok)
```

`by <hint>` attaches the justification to the obligation that needs it. `by` has
strong priors from Isabelle (`by simp`) and Lean (`by exact`), and it is
**extensible** — other hints can join `unfold(f)` later without new syntax.

Mechanically, `unfold(f)` adds the defining axiom `∀x. f(x) = <body>` to the
proof context for that obligation only.

The asymmetry is the design: **assuming an opaque predicate is free; establishing
one costs an unfold**, declared where a reader will see it.

Note this is the only viable granularity anyway — Thermite has **no `assert` and
no proof blocks** (verified: zero occurrences), so there is no way to interleave
proof steps in a body.

### `opaque` and linearity are keywords, not attributes

They change what the item *is*, not how it is processed. Modifier-before-item is
Rust's own pattern (`pub struct`, `unsafe fn`, `const fn`).

```thermite
opaque spec fn plan_ok(p: Plan) -> bool
once   struct Grant { base: u64, len: u64 }
```

### Trivial clauses get sugar

```thermite
requires  anything
ensures   nothing
```

These are the trivial cases *in the right direction*: the trivial precondition is
"any input is fine"; the trivial postcondition is "I promise nothing". One word
for both would lose that.

`ensures nothing` is meant to look alarming — an unconstrained function should.
The risk is that it misreads as "ensures nothing bad happens", which is the
opposite. `true` stays legal inside expressions; the sugar is clause-level only.

### `spec fn` gains `ensures`

Without it an opaque predicate is useless — callers could conclude nothing from
it and the seal would be pointless.

```thermite
opaque spec fn plan_ok(p: Plan) -> bool
  exhausts p.count
  ensures  !result || p.count > 0     // the interface, visible while sealed
{ ...expensive, quantifies over p.regions... }
```

This is abstraction with an interface: consumers reason from the stated
properties, not the definition. It is how large proof developments stay
tractable, and `ensures` already exists on `fn`.

## Open naming questions

**Linearity.** The property is *exactly* once — neither duplicated nor dropped.
Thermite's default is already affine (at-most-once), so the keyword marks the
no-drop upgrade.

| candidate | for | against |
|---|---|---|
| `once` | says exactly-once, contrasts with the affine default | may read as "one-time" temporally |
| `consumed` | participle form has precedent in `#[sealed]` | names only the drop side, not duplication |
| `spent` | evocative of a resource | same one-sidedness |
| `accounted` | every one must be accounted for | vague |

Current lean: `once`.

**Termination measure.** A well-founded quantity that strictly decreases.
`decreases` describes the expression's property rather than the clause's purpose.

| candidate | for | against |
|---|---|---|
| `terminates by` | self-documenting; purpose plus mechanism | a preposition inside a clause |
| `exhausts` | evocative — a finite resource used up | must infer that it is about termination |
| `descends` | names the mathematical structure (descending chain) | "descends what?" — same grammar gap |

Current lean: `terminates by` on agent-legibility grounds; `exhausts` is close.

## Worked example

```thermite
opaque spec fn plan_ok(p: Plan) -> bool
  exhausts p.count
  ensures  !result || p.count > 0

shared shootdown: Shoot

once struct Grant { base: u64, len: u64, generation: u64 }

struct Shoot { epoch: u64, acked: u64, expected: u64 }
  invariant acked & !expected == 0

fn acknowledge(s: &mut Shoot, cpu: u64) -> ()
  ! write(shootdown)
  requires  cpu < 64 && (s.expected >> cpu) & 1 == 1
  ensures   (final(s).acked >> cpu) & 1 == 1
  concurrent {
    asks      final(s).acked | s.acked == final(s).acked
    promises  final(s).acked == s.acked | (1 << cpu)
  }

fn region_count(p: Plan) -> u64          // assumes plan_ok — pays one symbol
  ! pure
  requires  plan_ok(p)
  ensures   result > 0

fn build(regions: Vec<u64>) -> Result<Plan, u64>   // establishes it — unfolds
  ! allocate
  requires  anything
  ensures   match result { Ok(p) => plan_ok(p), Err(e) => true }
            by unfold(plan_ok)
```

## The gap none of this closes

**G12.** Every function above returning `Result<Struct, _>` will hit Forge's
mutation-equivalence probe, which supports only scalar returns, so survivors are
counted rather than excluded and the contract is judged weak. Reproduced in a
four-line example during design.

Syntax does not fix it, and it is the thing most likely to make the whole set
unusable in Forge's own terms.
