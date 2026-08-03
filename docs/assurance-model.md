# The assurance model

What a Bulla certificate claims, and the vocabulary for saying it precisely.

> **Tracking note.** This vocabulary follows Thermite RFC-2 (the certification
> surface), which is proposed and not yet accepted upstream. Until it lands,
> Bulla records the full tuple internally and renders whatever Thermite's
> shipped schema provides. If RFC-2 is rejected or changed, this document
> changes with it.

## Why not a single level number

A scalar assurance level cannot carry what a certificate needs to say, because
the underlying order is genuinely partial. Two mechanisms can differ in opposite
directions at once: a solver route may refute better while being trusted less
than a kernel-checked proof. Collapsing those into one number requires inventing
a comparison, and an invented comparison eventually gets treated as real.

So a claim is a **tuple**, not a rung.

## The four coordinates

```
scope / refutation / trust @ boundary
```

**Scope** — what the claim quantifies over: `all`, `bounded(n)`, `per-exec`,
`none`.

**Refutation** — what a *false* clause yields. This is a property of the logical
fragment, not of the proof:

| value | meaning |
|---|---|
| `complete` | mechanically complete in-fragment: a false clause always yields a concrete countermodel |
| `incomplete` | a countermodel when the solver finds one; `unknown` is possible |
| `empirical` | no mechanical refutation; only a seeded generator attacking executable semantics |
| `trace(n)` | a concrete trace within the bound |
| `abort` | detected in production, at the violating call |
| `none` | — |

**Trust** — what you must believe. A *set*, because routes can require several
things at once:

| value | meaning |
|---|---|
| `lean-checked` | Lean re-checked the actual theorem; the solver is a proof producer and leaves the trusted base |
| `lean-lemma` | Lean proved a bridge lemma licensing the route; the solver **remains** trusted |
| `solver` | Z3/Verus soundness, per query |
| `fiat` | trusted by declaration |

`inspection` is a modifier rather than a value: renderer correspondence stays
inspection-tier even after reconstruction.

**Boundary** — how far the claim closes: `e2e`, `to_boundary`,
`to_platform(p)`.

## Why the boundary coordinate matters here more than anywhere

A kernel is mostly boundary. Every privileged operation — every MMIO write,
every page-table load, every IPI — is a call into a body that is *assumed*, not
proven. So a Bulla certificate that said only "proven for all inputs" would be
close to meaningless.

`to_platform(p)` names the specific frozen registry the claim closes against.
The registry is the TCB, and it is enumerable: that is the entire point of the
project.

A kernel claim without its boundary coordinate is not a weaker claim. It is an
unreadable one.

## Aggregation is deliberately unspecified

Composing clause tuples into an item tuple, and item tuples into an artifact
tuple, is **not** per-axis minimum. The axes interact:

- **Refutation is fibered over scope.** `complete` means complete *relative to
  the scope claimed*. `bounded(8)/trace(8)` and `all/complete` both say
  "complete" and mean different strengths.
- **Boundary acts on refutation.** A clause that is completely refutable
  `@to_boundary` is completely refutable *modulo the assumption*. A counterexample
  to the whole-program property can live inside the foreign body, where no
  channel observes it.
- **Trust is not a flat set.** It splits into residual risk (which grows under
  composition) and discharged evidence (which does not represent a liability).

Until that algebra is characterized, Bulla reports **per-clause tuples and the
weakest link on each axis separately**, and does not compute a single composite
claim. Reporting less is the honest option.

## The rule

> Any assurance statement in this repository must be reducible to a set of
> per-clause tuples with named boundaries. A prose summary that cannot be
> expanded into tuples is not a claim; it is marketing, and it does not belong
> in the documentation.

This applies to the README, to release notes, and to anything said about the
project elsewhere.
