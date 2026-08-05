# Protocol types for channels

**Rung 7.** Kind: new item form. Orthogonal to the effect-rows RFC through the
interference-clauses RFC.

## Summary

Those RFCs type the **shared state** between concurrent parties. This types the
**conversation** between them. A kernel with a static IPC topology is an
unusually good fit, because the protocol is known at build time.

## Proposal

```thermite
protocol PageRequest {
  user     sends { op: u32, count: u64 },
  provider sends { status: u32, base: u64 },
  end,
}

fn pager(c: provides PageRequest) -> ()
  ! blocks
  requires  nothing
  ensures   nothing

fn app(c: uses PageRequest) -> ()
  ! blocks
  requires  nothing
  ensures   nothing
```

Each step names the party that sends, so direction needs no glyph. `provides` and
`uses` name what an endpoint offers rather than its position in a topology, and
the endpoint type stands alone — no `Channel<>` wrapper, because the endpoint
*is* the type. `dual` was rejected as a mathematician's word for the mirror of a
thing, and `client`/`server` bakes in an assumption about who connects to whom.

Branching, which real protocols need:

```thermite
protocol Request {
  user sends { op: u32 },
  picks {
    ok:  provider sends { value: u64 },
    err: provider sends { code: u32 },
  },
  end,
}
```

## What it buys

- **Protocol conformance.** A party that sends when it should receive fails to
  typecheck.
- **Deadlock freedom, free.** For binary sessions, duality gives it structurally.
- **Session fidelity.** The conversation ends where `end` says it does.

For a decomposed Unix — filesystem server, network server, process server — this
is the difference between "the servers are isolated" and "the protocol between
them cannot desynchronise".

## A channel is shared state, and the protocol is its discipline

Worth stating plainly, because the effect row's treatment of channels only makes
sense once it is.

Two parties observe one channel, so a channel *is* shared state. It does not
appear in the effect row the way `shared shootdown: Shoot` does, and the reason
is not that it is less shared — it is that its discipline lives somewhere else.
For memory, the discipline is a lock (the shared-state-invariants RFC) or a
rely-guarantee pair (the interference-clauses RFC), and the effect row is what
carries it. For a channel, **the protocol type is the discipline**: at each step
the type names exactly one party that may send, so the interleaving that would
be a race is not expressible.

Three things follow, and each is a requirement rather than an observation.

**Endpoints must be resources, not merely affine.** The first draft listed this
as an open question that this RFC "probably depends on". It certainly does, in
both directions. Duplicating an endpoint would put two parties at one step, which
is the race the protocol is supposed to exclude. Dropping one abandons the peer
mid-session, blocked on a message that will never come — and affine types permit
dropping. So an endpoint is `resource` per
[resource types](resource-types.md), and this RFC does not stand at rung 7
without rung 5.

**The effect row carries only `blocks`.** Per
[the surface conventions](surface-conventions.md), a `shared` thing is named in
the row and a `resource` thing is not, because ownership already establishes
exclusivity. An endpoint arrives as an owned parameter, so there is no conflict
for the row to decide and nothing to name. What remains is that the function can
wait, which is a control effect.

**An endpoint may not be stored in `shared` state.** This is the restriction the
other two rest on. If an endpoint were reachable from a `shared` declaration,
two functions could reach the same endpoint by name, ownership would no longer
establish exclusivity, and both the bare `blocks` row and the protocol's
one-sender-per-step guarantee would fail at once. The surface conventions flag
this as the condition under which the effect-row rule stops holding; enforcing it
belongs here, as a rejection at the `shared` declaration.

The payoff of getting this shape right is that an endpoint may cross a
concurrency boundary safely. Handing a session to another CPU is a move, not a
copy, so the protocol's guarantees travel with it — which is what makes a
decomposed kernel's servers relocatable rather than pinned.

## Metatheory

Session types (Honda, 1993; Honda, Vasconcelos and Kubo, 1998). Binary session
duality and its deadlock-freedom result are settled. Multiparty session types
(Honda, Yoshida and Carbone, 2008) generalise beyond two parties and are
substantially harder — this RFC proposes binary only.

## Open questions

- **Failure.** What is the protocol type of a partition that crashes mid-session?
  Real systems need a cancellation story and session types are traditionally weak
  on it. This is also where the endpoint-is-a-resource rule meets the `panic`
  question from [resource types](resource-types.md): an aborting party drops its
  endpoint, and the peer's blocked wait is the observable consequence.
