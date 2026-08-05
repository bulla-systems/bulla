# Protocol types for channels

**Rung 7.** Kind: new item form. Orthogonal to the effect-rows RFC through the interference-clauses RFC.

## Summary

Those RFCs type the **shared state** between concurrent parties. This types the
**conversation** between them. A kernel with a static IPC topology is an unusually
good fit, because the protocol is known at build time.

## Proposal

```thermite
proto PageRequest {
  -> { op: u32, count: u64 },
  <- { status: u32, base: u64 },
  end,
}

fn pager(c: Chan<co PageRequest>) -> ()
  req  true
  ens  true
  fx   chan(page_request)
```

`->` sends, `<-` receives: direction-obvious without jargon. `proto` rather than
`session` says what it is to a reader who has not read the literature. `co T` is
the dual endpoint.

Branching, which real protocols need:

```thermite
proto Request {
  -> { op: u32 },
  pick {
    ok:  <- { value: u64 },
    err: <- { code: u32 },
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

## Metatheory

Session types (Honda, 1993; Honda, Vasconcelos and Kubo, 1998). Binary session
duality and its deadlock-freedom result are settled. Multiparty session types
(Honda, Yoshida and Carbone, 2008) generalise beyond two parties and are
substantially harder — this RFC proposes binary only.

## Open questions

- **Linearity of channel endpoints.** A session channel must be used exactly
  once per step, which is [resource types](resource-types.md). This RFC probably
  depends on that one.
- **Failure.** What is the protocol type of a partition that crashes mid-session?
  Real systems need a cancellation story and session types are traditionally
  weak on it.
