# RFC-007 — A `crash` clause for durable state

**Unscheduled.** Kind: one new clause, shaped like `ens`.

## Why it is here

Crash consistency was initially filed as outside the project's reach. That was
wrong, and this document records the correction.

Every obligation in Thermite has the shape "every transition preserves I". A
crash is not a transition of the program: it is an external event that can land
*mid-step*, mapping volatile state to whatever reached durable storage —
nondeterministically, since caching and reordering decide what survived.

So the obligation gains a case:

```
normal:  I(s) ⟹ I(δ(s, e))
crash:   I(s) ∧ crash(s, d) ∧ recover(d) = s′ ⟹ I(s′)
```

Structurally that is *a relation you do not control interfering with your step* —
the same shape as [RFC-005](005-interference-clauses.md)'s `<~`, with the
environment being physics rather than another CPU.

## Proposal

```thermite
fn commit(j: &mut Journal, b: Block) -> ()
  req    j.open && b.len <= MAX_BLOCK
  ens    final(j).committed == j.committed + 1
  crash  final(j).recoverable
         && (final(j).committed == j.committed
             || final(j).committed == j.committed + 1)
  fx     write(disk)
```

`crash` states what holds if execution stops at *any* point inside the function.
The classic journalling obligation — the commit either happened or did not, never
half — is exactly that disjunction.

## Metatheory

Crash Hoare Logic (Chen et al., FSCQ, SOSP 2015), mechanised in Coq. Settled.

The work is not the logic. It is the **crash model**: which writes may be lost or
reordered depends on the device and the barriers issued, so the model is a
per-device assumption that must be stated as plainly as any other trusted input.

## Why it is unscheduled

Nothing in Bulla has durable state yet. Filesystems are outside the verified core
at every rung of [the ladder](../the-ladder.md), so this becomes relevant only if
a journal or a persistent capability store moves inside.

Recorded now because the correction is worth keeping: this is a rung we have not
scheduled, not a barrier.
