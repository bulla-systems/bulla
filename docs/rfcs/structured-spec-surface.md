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

## 1. A recursive `spec fn` has its `bool` return type rewritten to `nat`

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

The declared `-> bool` is discarded and `nat` emitted in its place. Isolated:

| | result |
|---|---|
| non-recursive, ADT measure, `-> bool` | L3 |
| recursive, scalar measure, `-> bool` | L3 |
| recursive, ADT measure, `-> u64` | L3 |
| **recursive, ADT measure, `-> bool`** | **rewritten to `nat`** |

So the trigger is the combination, and the fix is to stop assuming a measure
return type for recursive spec functions.

**Why this one matters most.** Structural induction yielding a predicate is how
you state properties of trees. A page table is a four-level tree, and "this table
maps no address outside the partition" is the property memory isolation actually
rests on. This defect is the difference between a kernel that can only *build*
address spaces and one that can *validate* them.

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
spec functions. Nothing semantic distinguishes them — the per-struct check
harness simply does not weave the library in.

Same class as [#122](https://github.com/dollspace-gay/Thermite/issues/122), where
the same harness does not weave type declarations.

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
