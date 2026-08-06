# Complete the spec surface of structured data

**Rungs 1 and 2.** Kind: **defect report**, not a feature request. Every item
below is something the language already intends to support, reproduced against
Thermite at the pin.

## Summary

Collections and recursive data have a complete *executable* surface and an
incomplete *specification* surface. You can hold a `Vec<u64>` in a struct and
push to it; you cannot say anything about its contents in `req`, `ens`, or `inv`.
You can define a recursive tree and compute its depth in spec; you cannot state a
predicate over its leaves.

Four items. Three are mechanical. One shares a root cause with
[#122](https://github.com/dollspace-gay/Thermite/issues/122).

## 1. A `spec fn` over an ADT has its declared `bool` return rewritten to `nat`

```thermite
enum Tree { Leaf(u64), Node(Box<Tree>, Box<Tree>) }

spec fn all_below(t: Tree, limit: u64) -> bool
  dec t
{ match t { Leaf(v) => v < limit, Node(l, r) => all_below(*l, limit) && all_below(*r, limit) } }
```
```
error[E0308]: mismatched types
10 | pub open spec fn all_below(t: Tree, limit: u64) -> nat
   |                                                    --- expected `nat` because of return type
14 |     Tree::Leaf(v) => v < limit,
```

The declared `-> bool` is discarded and `nat` emitted in its place.

**The trigger is a body shape, not recursion and not the measure.** An earlier
draft of this report attributed it to "recursive spec functions" and proposed
"stop assuming a measure return type" as the fix. Both are wrong, and a
**non-recursive** function reproduces it:

```thermite
spec fn depth(t: Tree) -> u64
  dec t
{ match t { Tree::Leaf(v) => 1, Tree::Node(l, r) => 1 + depth(*l) } }

spec fn calls_it(t: Tree) -> bool          // not recursive
  dec t
{ match t { Tree::Leaf(v) => true, Tree::Node(l, r) => depth(*l) > 0 } }
```
```
20 | pub open spec fn calls_it(t: Tree) -> nat
24 |             Tree::Leaf(v) => true,
```

`depth` certifies at L3. `calls_it` does not, and it calls itself nowhere.

### The mechanism

`is_adt_fold_sum` (`thermite-lower/src/lower.rs:4078`) classifies a body as a
numeric fold when its tail is a `Match` and **any arm contains a call with a
deref argument** — `f(*x)` — via `expr_has_deref_call_arg` (`:4096`). A body so
classified joins the program-wide `nat_fns` set (`:891`) and is lowered with a
`nat` return.

The declared return type is not consulted anywhere in that path.

The classifier was built for numeric folds, and its own comment says why the
return is forced: the base arms "are coerced to `nat` uniformly with the
recursive arm by the `nat` return". That is right for `sum_list` and wrong for
any ADT match that happens to call through a `Box` deref.

### The fix

Gate the classification on the declared return type: a `spec fn` declared
`-> bool` does not join `nat_fns`. The guard belongs at the `filter_map` building
that set, where the item is in hand.

### Why this one matters most

Structural induction yielding a predicate is how you state properties of trees. A
page table is a four-level tree, and "this table maps no address outside the
partition" is the property memory isolation actually rests on. This defect is the
difference between a kernel that can only *build* address spaces and one that can
*validate* them.

## 2. `Vec` indexing in spec position emits an idiom the wrapper does not support

```thermite
fn f(xs: Vec<u64>) -> u64 req xs.len() > 0 ens result == xs[0] fx alloc { xs[0] }
```
```
error[E0599]: no method named `view` found for struct `TVecU64`
   | ... xs@[i as int] ...
```

The emitter writes `xs@` — Verus's view operator — but the generated `TVecU64`
wrapper does not implement `View`.

**The wrapper already emits `spec_get`.** So the capability exists and the
emitter is reaching for the wrong idiom; emitting `spec_get` is the minimal fix,
implementing `View` the more general one.

## 3. Combinators are not in scope inside an `inv` clause

```thermite
struct S { xs: Vec<u32> } inv forall_in(xs, |x| x < 100)
```
```
error[E0425]: cannot find function `forall_in` in this scope
```

A struct invariant **can** call a user `spec fn` (verified: L3). Combinators are
spec functions. Nothing semantic distinguishes them.

### The mechanism

Combinator definitions are emitted on demand, from a walk that collects the names
a program references. The driver (`thermite-lower/src/lower.rs:1783`) has an arm
for a function's `req` and `ens`, an arm for its body's loop clauses, and an arm
for a `spec fn`'s `dec` and body:

```
collect_combinators_in_expr(&f.contract.req.expr, …)
collect_combinators_in_expr(&ens.expr, …)
collect_combinators_in_block_specs(body, …)
collect_combinators_in_expr(&s.dec.expr, …)
collect_combinators_in_block_specs(&s.body, …)
```

There is **no arm for a struct or enum `inv`**. A combinator named there is never
collected, so its definition is never emitted, so the reference does not resolve.

The fix is an arm walking the `inv` expression.

### Not the same defect as #122

An earlier draft called this the same harness fault as
[#122](https://github.com/dollspace-gay/Thermite/issues/122) and suggested filing
it as a comment there. Checking the code, they are different paths with different
fixes: #122 is `item_subprogram`'s ADT arm not weaving a declaration it depends
on, in `forge/src/check.rs`; this is the combinator collection walk in
`thermite-lower` having no ADT arm at all. They rhyme — the struct path fails to
gather something it needs, twice — and they are not one bug.

## 4. A spec closure does not elaborate in value position

```thermite
ens result == forall_in(xs, |x| x != n)
```
```
error[E0308]: expected `FnSpec<(u32,), bool>`, found closure
```

Value position itself is fine — `ens result == user_spec_fn(a)` reaches L3, and
`forall_in` works in `req` and in `ens` proposition position. The obstacle is
closure elaboration in that context alone.

## Why it survives

No `.th` in `conformance/` holds a struct with a user-declared field type, and
none quantifies over a `Vec` or `Map` field. The corpus reaches slices, which
*do* have a working spec surface — `binary_search.th` indexes and quantifies over
`&[u32]` at L3. The asymmetry between slices and the bounded wrappers is the
clearest evidence that this is unfinished rather than intended.

## The design caveat that belongs in any fix

A collection-quantifying invariant is folded into **every** obligation touching
that type, as a precondition and a postcondition at every use site. So an
expensive invariant multiplies solver load across the whole program.

That is a question about whether to *encourage* the pattern, not whether it is
sound. Naming it matters: a fix that makes something possible but intractable is
worse than one that arrives with guidance about when to use it.

## Relationship to other filings

[#123](https://github.com/dollspace-gay/Thermite/issues/123) reports `Map`'s
missing `remove` and iteration — the **executable** half of the same story. A
maintainer looking at either wants both in view.
