# Surface conventions

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
`ensures` do not collide. The abbreviation destroyed the information that would
have prevented the clash.

Note this is a departure from **both** parents. Verus uses full words
(`ensures` 804, `requires` 465, `decreases` 161, `invariant` 117 in vstd); Rust
is mixed, abbreviating only its most ubiquitous tokens (`fn`, `mut`, `pub`).
Thermite's `req`/`ens`/`fx`/`inv`/`dec` is neither.

## The clause grammar

Every clause is a **third-person-singular verb whose subject is the item**. A
clause is a sentence with the subject elided, and the item supplies it.

```
f          requires  n < 100
f          ensures   result == n * 2
f          survives  final(j).recoverable
f          measures  p.count
the loop   keeps     acked & !expected == 0
Grant      keeps     base + len <= MAX_PHYS
```

This is a rule rather than a preference, and it decided several names below. It
also identifies the one clause the language already ships that breaks it:
`inv` is a noun in a verb slot, which is why it never sat right beside `req` and
`ens`. `requires`, `ensures`, `asks` and `promises` already obey the rule; the
clause that does not is the one that was inherited rather than chosen.

Three things are exempt, and the rule says why rather than excusing them.

**The effect row** is not a sentence the item asserts. `() ! pure` and
`() ! write(shootdown)` are different types, so the row belongs to the arrow.
A thing that is not a sentence is not conjugated.

**Block headers** take no predicate. `interleaves { }` heads a scope, as `loop`
and `match` do.

**Modifiers** are adjectives on an item, not clauses: `opaque spec fn`,
`resource struct`.

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
on fn        requires  ensures  survives  interleaves { asks  promises }  measures
on struct    keeps
on spec fn   ensures  measures
on loop      keeps  measures
type-level   ! <effect row>
modifiers    opaque  resource
```

Ordering is mandatory, as it is today. The rule is syntactic:

```
1. the effect row          — it is part of the type
2. bare clauses            — requires, ensures, survives
3. blocks                  — interleaves { }
4. measures                — last, as Verus places `decreases`
```

Nothing semantic has to be known to check that order, and the grouping that used
to be carried by an ordering convention is carried by the `interleaves` block
instead.

**This is a breaking reorder.** Today the enforced order is `req` ×1, `ens` ×1+,
`fx` ×1 last (`parse_contract`, parser.md REQ-2), verified by probe: `ens` before
`req`, `fx` first, and a second `req` after `ens` all fail with
`clause 'req' is out of order in 'f'`. Moving the effect row from last to first
invalidates every existing `.th`. The change is mechanical, and it was not stated
in the previous draft of this document.

## Decisions

### Effects belong to the arrow, not the predicates

`effects E` was grammatically out of place — a noun phrase among verb phrases —
because it is not a claim about behaviour. It is part of the type.

The sharper statement, which also draws the line between the row and the clauses:

> **An effect propagates up the call graph by construction. A clause is proved at
> the item.**

A caller of a `write(sched)` function writes `sched`. A caller of a panicking
function may panic. A caller of a 25-unit function spends 25 units. None of that
is true of `requires`, `ensures`, `keeps` or `measures`, which are discharged
locally and stop there. Things that travel along the arrow are part of it.

```thermite
fn allocate(pages: u64) -> Result<Grant, u64>
  ! write(heap)
  requires  pages > 0 && pages <= 1024
  ensures   ...
```

Its own line, marked by a symbol, sitting between the signature and the
predicates. `! pure` reads where `with pure` did not.

### The effect row is two families of label

The row as inherited holds three different kinds of thing in one flat list:

```
fx write(disk), alloc, time, rand, channel, panic, diverge
```

`write(disk)` names a resource and a mode. `alloc`, `time` and `rand` name
resources with both the mode and the name suppressed. `channel` names a kind.
`panic` and `diverge` name no resource, because there is none — they are
statements about the arrow.

Two families, each with a fixed shape:

| family | shape | examples | composition |
|---|---|---|---|
| state | names a region | `read(r)`, `write(r)`, `forgets(r)` | union |
| control | describes the arrow | `panic`, `blocks`, `diverge`, `cost(E)` | or; sum for `cost` |

`forgets(r)` is [resource types](resource-types.md)'s abandonment operation, and
it is a state effect for the ordinary reason: it names the region the abandoned
resource came from, and a caller inherits it.

A state effect always names its region, and a control effect never does, so the
shape is the discriminator and no reader has to be told which family a label
belongs to.

An effect label is three things: **a name, the kind of argument it takes, and how
two of them combine.** That last part is what makes the row composable rather
than a list of permissions, and it is what lets a future label join without new
syntax — the same extensibility argument that decided `by <hint>` below.

### Which effects name their resource

> **A `shared` thing is named in the row. A `resource` thing is not, because
> ownership already gives exclusivity.**

Two functions can reach the same `shared` item by name, so conflict has to be
decided by name: `write(shootdown)` and `write(scheduler)` are compatible,
`write(shootdown)` twice is not. A `resource` endpoint cannot be aliased or
duplicated, so two functions can never hold the same one, there is nothing for
the conflict rule to decide, and the kind suffices.

An earlier version of this rule said the row *names what the signature does not*.
That does not discriminate the case it was written for:
`acknowledge(s: &mut Shoot, cpu: u64)` takes the shared state as a parameter too,
and `&mut Shoot` names a type rather than an identity in the same way
`c: provides PageRequest` does.

The version above also absorbs a caveat the earlier one had to state as an
exception. If a channel endpoint were ever reachable from global state, the rule
keeps working, because the thing reached is `shared` and the `shared` item is
what gets named.

### The ambient effects are shared state with the name suppressed

`alloc`, `time` and `rand` all touch ambient mutable state. Declaring that state
removes them as special atoms:

```thermite
shared heap:    Heap
shared clock:   Clock
shared entropy: Entropy
```
```thermite
fn allocate(pages: u64) -> Result<Grant, u64>   ! write(heap)
fn now() -> u64                                  ! read(clock)
fn next() -> u64                                 ! write(entropy)
```

Four ad-hoc atoms collapse into one concept, and the conflict rule of
[verified effect rows](verified-effect-rows.md) then applies to them uniformly, which it
does not today.

There is a result in that beyond tidiness. Making the heap a region means every
allocating function conflicts with every other, so allocation serialises. That is
correct for a single global allocator, and it is currently invisible. It also
makes the fix expressible: per-CPU heaps are separate regions, so
`write(heap_of(cpu))` is what stops them conflicting.

### `channel` is a control effect, and its content is waiting

`! channel` carried no information, for the reason the rule above gives: the
endpoint is a `resource` value, so ownership already establishes exclusivity and
there is nothing to name. The function does have an effect — it can wait.

```thermite
fn pager(c: provides PageRequest) -> ()   ! blocks
```

`blocks` is liveness-relevant, so it is recorded and not proved, which is the
status of every liveness claim in this project.

### `diverge` is declared, and it costs a level

Thermite already implements this, and the probe records the rule verbatim:

```
recursive function `countdown` must have a decreases clause — a `fn` that calls
itself MUST supply a `dec <measure>` so termination is proved (§4.1;
`.design/basis/10-recursion-tuples.md` REQ-2), UNLESS it declares `fx diverge`
```

Declaring the escape hatch drops the item from **L3 to L1**. Divergence is
available, priced, and visible in the certificate. So `diverge` stays in the row
rather than being inferred from a missing `measures`: the measure is the local
proof, and the effect is the propagated consequence.

The rule is not applied uniformly, and one of the two exceptions is a defect.
Spec functions require a measure with no escape, which is correct — a spec
function is used in logic, so totality is a soundness condition. Loops require
one with no escape, which is
[G14](../language-gaps.md#g14-a-loop-has-no-diverge-exemption): an intentionally
infinite loop is only writable by supplying a measure that cannot decrease.

### Interference is grouped, and the block is a verb

`requires`/`ensures` are about *this* execution at its endpoints.
`asks`/`promises` are about *other* executions during it. Parallel but on a
different axis, and a flat list hides that.

```thermite
  requires  cpu < 64 && (s.expected >> cpu) & 1 == 1
  ensures   (final(s).acked >> cpu) & 1 == 1
  interleaves {
    asks      final(s).acked | s.acked == final(s).acked;
    promises  final(s).acked == s.acked | (1 << cpu);
  }
```

The block does three jobs: it names the axis, groups the pair, and marks the
function concurrent, so no `conc` effect atom is needed.

`interleaves` rather than `concurrent` because the block sits in the contract,
among clauses, where a reader is reading verbs. The obvious alternative is
`shares`, which would pair with `shared shootdown: Shoot`, and it is wrong: a
function can touch shared state with no concurrent interference, and with checked
rows `! write(shootdown)` already says it touches that state. What the block adds
is that the execution may overlap another. The word is also native here —
[G2](../language-gaps.md#g2-no-concurrency-semantics) already describes its third
direction as "a sequential model plus an interleaving obligation".

**The block is load-bearing.** `requires`/`ensures` is *also* ask-and-promise, to
the caller rather than the environment; only the block distinguishes the party.
So a bare `asks` at contract level is not meaningless, it is ambiguous between
two readings with different parties, and resolving it the wrong way proves
something about the wrong thing. That is what earns a parse error rather than a
lint.

**The mechanism is the absence of a production.** `asks` and `promises` become
reserved keywords in `keyword_kind`, and the only production consuming them is
the one parsing the body of `interleaves { }`. Anywhere else they reach the
unexpected-token arm. There is no separate check to write and no pass that could
be skipped. What should be added is a dedicated diagnostic beside the existing
`MissingClause` and `ClauseOrder` variants, so the message names the cause:

```
clause `asks` appears outside an `interleaves` block in `acknowledge` (byte 118)
```

Both clauses are mandatory inside the block, matching the house style that `req`
and `ens` are both mandatory on a function. The conservative rely is written
`asks nothing` rather than left implicit.

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

fn pager(c: provides PageRequest) -> () ! blocks
fn app(c: uses PageRequest)       -> () ! blocks
```

`provides` / `uses` reads as English, carries no topology assumption, and the
endpoint type stands alone — no `Channel<>` wrapper needed, because the endpoint
*is* the type.

### A clause body is a block of conjuncts

```thermite
  requires {
    cpu < 64;
    (s.expected >> cpu) & 1 == 1;
  }
  ensures {
    (final(s).acked >> cpu) & 1 == 1;
    match result { Ok(p) => plan_ok(p), Err(e) => true } by unfold(plan_ok);
  }
```

The bare single-expression form stays as sugar: `requires n < 100` is
`requires { n < 100; }`.

This buys two things beyond reading better than a repeated keyword.

**It makes `by` work per obligation.** A conjunct is an obligation, so a hint
attaches to the condition that needs it rather than to a compound clause.

**Addressing already expects it.** `validate_segments` accepts `req#k` and `ens#k`
ordinals today while `parse_contract` takes exactly one `req`. The address layer
was built for a clause with numbered parts and the parser never grew them.

It also regularises the nesting: an item holds clauses, a clause holds conjuncts.
`interleaves { }` is then not a special case, it is a block one level up holding
clauses rather than conjuncts.

`measures` is the exception, and the exception preserves the rule. A lexicographic
measure is an ordered tuple rather than a conjunction, so it takes a comma list —
`measures x, y` — and a block continues to mean "and" everywhere it appears.

### Opacity is discharged per obligation, not per function

An earlier `unfolds` clause was wrong because it is not a claim about behaviour —
it is a proof hint. But a *function-level* hint is also too coarse.

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

`by` is reserved for hints alone, which is what ruled out `terminates by` as a
measure clause. A single token introducing a measure in one clause and a
justification in the next is the `guar`/`ens` collision in a new costume.

### `opaque` and `resource` are keywords, not attributes

They change what the item *is*, not how it is processed. Modifier-before-item is
Rust's own pattern (`pub struct`, `unsafe fn`, `const fn`).

```thermite
opaque   spec fn plan_ok(p: Plan) -> bool
resource struct Grant { base: u64, len: u64 }
```

### Trivial clauses are `nothing`

```thermite
requires  nothing
ensures   nothing
asks      nothing
promises  nothing
```

An earlier draft had `requires anything` against `ensures nothing`, on the
grounds that the two trivial cases point in opposite directions: a trivial
precondition is generous to callers, a trivial postcondition is uninformative to
them.

The distinction is real and the object was the wrong place to carry it. Under the
clause grammar, `f requires anything` is not a sentence anyone means — "requires
anything" reads as *requires whatever*, and the intended sense only survives
under negation, as "does not require anything". **The verb already carries the
direction**: `requires nothing` reads as unremarkable and `ensures nothing` reads
as alarming without either word doing the work.

It also removes an inversion hazard on the concurrent axis. `asks anything` could
be read as demanding everything of the environment, which is the inverse of the
intended meaning and would license a vacuous proof. `asks nothing` has one
reading: this function asks nothing of its peers, so it must survive whatever
they do.

The genuinely dangerous case keeps no sugar. An unsatisfiable precondition makes
every obligation vacuously true, and it is written `requires false` with the
literal, which looks unusual.

### `spec fn` gains `ensures`

Without it an opaque predicate is useless — callers could conclude nothing from
it and the seal would be pointless.

```thermite
opaque spec fn plan_ok(p: Plan) -> bool
  ensures   !result || p.count > 0     // the interface, visible while sealed
  measures  p.count
{ ...expensive, quantifies over p.regions... }
```

This is abstraction with an interface: consumers reason from the stated
properties rather than the definition. It is how large proof developments stay
tractable, and `ensures` already exists on `fn`.

## The names, and why

### `resource` for linearity

The property is exactly once — neither duplicated nor dropped. Thermite's default
is already affine, so the keyword marks the no-drop upgrade.

The candidates that failed, and the filter each one failed:

| candidate | why not |
|---|---|
| `linear` | names the mathematics rather than the property, which is what retired `region` for `shared` |
| `once`, `used` | describe what happens *to* the value, so they land as an adverb or a participle in an adjective slot; `once` also reads as Rust's `std::sync::Once`, and `used` as Rust's `#[used]` |
| `consumed`, `spent`, `owed` | past participles, so they describe a state the value is already in rather than an obligation on its use |
| `accountable`, `owing`, `custodial` | name the obligation correctly but point outward — accountable *to* whom, owed *to* whom |
| `undroppable` | precise and unambiguous, and a negation naming the prohibition rather than the property |

Two things decided it.

**The keyword should name the half Rust does not already give.** Move semantics
are affine, so no-duplication is already enforced and a keyword covering it
restates what a reader believes Rust does. The delta is the silent drop.

**The modifier slot is an adjective slot** — `pub struct`, `unsafe fn`,
`opaque spec fn`. Every candidate above is an adverb, a participle, or a
relational adjective, because English forms "has been X-ed" freely and
"must be X-ed" barely at all.

`resource` escapes both by naming what the value **is** rather than what happens
to it, which is the move `shared` already makes for state. Both halves follow
from the kind: a copy of a resource would be a second claim on the same thing,
and a resource you fail to release is a **resource leak**, which is the named
failure in every systems vocabulary there is.

```thermite
resource struct Grant { base: u64, len: u64, generation: u64 }
shared   shootdown: Shoot
```

It also answers [resource types](resource-types.md)'s contagion question in English: a
struct with a resource field is a resource.

### `measures` for the termination measure

`decreases` names the expression's property rather than the clause's purpose.
Three candidates were carried into this pass, and two are ruled out on mechanism
rather than taste.

**`terminates by` is impossible.** A clause keyword is also a semantic-address
segment, and `validate_segments` splits on `.` against an allowlist. The error
class separates cleanly:

```
double.ens            → no such address     (segment well-formed)
small.dec             → no such address     (segment well-formed)
double.terminates by  → malformed address   (rejected before lookup)
```

A space-bearing keyword cannot be an address segment, so it would need a second
spelling for addressing — an asymmetry nothing else in the language has. `by` is
separately reserved for proof hints.

**`exhausts` collides with `resource`.** Exhausting a resource is the standard
phrase in that vocabulary, and resource exhaustion is the liveness property this
project explicitly does not claim. The collision was noted as conditional on the
linearity keyword; choosing `resource` fires it.

`measures` is what the expression is, it is one word and address-clean, and the
discipline follows from the kind as it does for `resource` and `shared`.

**The near-miss worth recording is `variant`** — the decreasing quantity of a
loop is the loop variant, the dual of the loop invariant, and Eiffel uses
`invariant`/`variant` as keywords. It dies on enum variants, which already mean
one arm of an enum to every reader of this language.

### `keeps` for the invariant

A noun in a verb slot, replaced under the clause grammar. `maintains` is the
textbook verb for loops and `satisfies` the accurate one for structs; `keeps` is
true of both and keeps the parallel.

```thermite
resource struct Grant { base: u64, len: u64, generation: u64 }
  keeps  base + len <= MAX_PHYS

loop {
  keeps     acked & !expected == 0
  measures  remaining
}
```

This renames a clause the corpus already uses, which no other decision here does.

### `survives` for the crash clause

[the crash clause](crash-clause.md) had `crash` as a bare noun. It is the crash-time
analogue of `ensures` — what holds if execution stops mid-step — so it conjugates
the same way.

```thermite
  survives  final(j).recoverable
            && (final(j).committed == j.committed
                || final(j).committed == j.committed + 1)
```

## Worked example

```thermite
opaque spec fn plan_ok(p: Plan) -> bool
  ensures   !result || p.count > 0
  measures  p.count

shared   shootdown: Shoot
shared   heap:      Heap

resource struct Grant { base: u64, len: u64, generation: u64 }
  keeps  base + len <= MAX_PHYS

struct Shoot { epoch: u64, acked: u64, expected: u64 }
  keeps  acked & !expected == 0

fn acknowledge(s: &mut Shoot, cpu: u64) -> ()
  ! write(shootdown)
  requires {
    cpu < 64;
    (s.expected >> cpu) & 1 == 1;
  }
  ensures  (final(s).acked >> cpu) & 1 == 1
  interleaves {
    asks      final(s).acked | s.acked == final(s).acked;
    promises  final(s).acked == s.acked | (1 << cpu);
  }

fn region_count(p: Plan) -> u64          // assumes plan_ok — pays one symbol
  ! pure
  requires  plan_ok(p)
  ensures   result > 0

fn build(regions: Vec<u64>) -> Result<Plan, u64>   // establishes it — unfolds
  ! write(heap)
  requires  nothing
  ensures   match result { Ok(p) => plan_ok(p), Err(e) => true }
            by unfold(plan_ok)
```

## What the probes established

Every verdict here is a `forge check` result at the pin, against Verus
`0.2026.05.24.ecee80a`.

| probe | verdict |
|---|---|
| `once` `spent` `consumed` `accounted` `exhausts` `descends` `terminates` `by` as function names | all L3 — every candidate keyword is a free identifier today |
| `ens` before `req`; `fx` first; a second `req` after `ens` | all three: `clause 'req' is out of order in 'f'` |
| `fx write(a_resource_that_does_not_exist), read(nor_this_one)` on a body that touches nothing | **L3** — the row is unchecked in both directions |
| `spec fn` with no measure, recursive or not | `missing the mandatory 'dec' clause` |
| recursive `fn` with no measure and no `diverge` | rejected, naming the `fx diverge` exemption |
| the same function with `fx diverge` | accepted at **L1** |
| a loop with `fx diverge` on the enclosing function and no measure | `missing the mandatory 'dec' clause` — G14 |
| address `double.ens`, `small.dec` | *no such address* |
| address `double.terminates by` | *malformed address* |

## The gap none of this closes

**G12.** Every function above returning `Result<Struct, _>` will hit Forge's
mutation-equivalence probe, which supports only scalar returns, so survivors are
counted rather than excluded and the contract is judged weak. Reproduced in a
four-line example during design.

Syntax does not fix it, and it is the thing most likely to make the whole set
unusable in Forge's own terms.
