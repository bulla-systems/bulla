# Architecture

Where Bulla's verified core begins and ends, why the line sits there, and what
shape the code inside it takes.

This is Bulla's own analysis. It replaces a document that described the
architecture of the upstream platform work this repository forked, which is being
withdrawn upstream. What changed is in
[section 10](#10-what-changed-from-the-inherited-architecture).

Everything here is design. Status is NOT STARTED throughout, with blockers named.

## 1. The kernel as a composition of transition systems

A subsystem is four things: states `S`, events `E`, a transition function
`δ : S × E → S`, and an invariant `I ⊆ S` — the property that makes it safe. To
verify it is to prove

```
for all s ∈ S, e ∈ E:   I(s)  ⟹  I(δ(s, e))
```

closed under every event. That is the whole obligation for one subsystem.

A kernel is many subsystems at once, so its state is the product `S₁ × … × Sₙ`
and its invariant is a predicate over that product. The cost of verifying it
depends on the *shape* of that predicate.

**If every invariant is local** — each `Iᵢ` a predicate on `Sᵢ` alone — the
system invariant is `⋀ᵢ Iᵢ`, and it holds as soon as each `δᵢ` preserves its own
`Iᵢ`. The subsystems never have to be reasoned about together. Cost is
**additive**: `Σᵢ cost(δᵢ)`.

**If an invariant is cross-cutting** — mentioning `Sᵢ` and `Sⱼ` together — no
per-subsystem proof establishes it. It must be proved against the joint
transition relation over the product space, considering every subsystem that can
touch either component. Cost becomes **multiplicative** in the interacting parts.

That difference is the design problem. It is also the honest reason microkernels
are small: keeping `n` low inside the boundary keeps the product small, whether
or not the invariants are local.

## 2. The meso position

A *microkernel* minimises `n`. A *monolithic* kernel maximises it and verifies
none of it. Bulla takes a middle position, and needs a principle rather than a
preference, because "somewhat more than a microkernel" is not an engineering
statement.

> **The rule.** A subsystem is admissible to the verified core when its invariant
> is local, or can be made local by an ownership discipline the language can
> enforce. It stays outside when its invariant is irreducibly cross-cutting.

The second clause is the interesting one. Section 3 is about it.

This is not the micro/mono line redrawn. It cuts across that line, admitting some
things a microkernel excludes and excluding at least one thing microkernels
traditionally keep.

## 3. Making invariants local: ownership as the lever

Whether an invariant is cross-cutting is not fixed. It is a property of the
*interface*, not of the subsystem.

Take an allocator and the property "no unit is handed out twice". Stated
directly, it mentions the allocator's records *and* every holder's state:
cross-cutting, and worse with each new holder.

Now change the interface. Let allocation return a **grant** — a value
representing the claim, which cannot be copied and must be given back to release.
The invariant becomes "each unit appears in at most one live grant", a statement
about the allocator's own state. That is local. Holders need no invariant at all,
because they cannot manufacture a second grant; the type system refuses.

The ownership discipline converted a multiplicative obligation into an additive
one. Nothing about the resource changed, only the interface.

**Thermite supports this today.** Declared types are affine: they move rather
than copy, and reusing a moved value is rejected.

```thermite
struct Tok { v: u64 }
fn take(t: Tok) -> u64 req true ens result == t.v fx pure { t.v }
fn twice(t: Tok) -> u64 ... { let a: u64 = take(t); let b: u64 = take(t); a + b }
```
```
error[E0382]: use of moved value: `t`
```

That rejection is the mechanism the meso position rests on. It comes from Rust's
move semantics, and it is *strengthened* by user structs having no `Copy`
([G11](language-gaps.md#g11-user-structs-have-no-copy-so-a-field-cannot-be-read-twice)) —
recorded earlier as a papercut, better understood as what makes grants
unforgeable.

What Thermite does **not** provide is a way to require that a grant is eventually
returned. Affine types permit dropping; linear types would not. The discipline
prevents *duplication* but not *leaks*. Duplication is the safety property;
leaking is liveness, and this architecture makes no liveness claims.

## 4. Applying the test

Each candidate subsystem, its natural invariant, and whether ownership makes it
local. These are design positions, not results.

| subsystem | natural invariant | local? | verdict |
|---|---|---|---|
| execution context | a context entered unprivileged is never resumed privileged; a stale generation is never resumable | yes, already state-local | **IN** |
| authority ledger | rights only narrow; generations only increase | yes, ledger-local | **IN** |
| frame allocator | no frame is in two live grants | yes, via an affine grant | **IN** |
| address-space plan | mapped ranges do not overlap; the privileged window is separate | yes, if the plan is one object rather than a set of mutable tables | **IN** |
| interrupt routing | each vector has at most one live route | yes, table-local | **IN** |
| timekeeping | readings are monotonic | yes | **IN** |
| scheduler | at most one thread Running per CPU; the runqueue agrees with each thread's state | **no**, as usually written | **IN, restructured** |
| message passing | every delivery is authorised; endpoints are live | no — relates two parties | **OUT** initially |
| device transfer isolation | no transfer target overlaps privileged memory | no — joint with the address-space plan | **OUT** |
| filesystems, network stack, drivers, userland | — | no | **OUT** |

Two rows need the argument spelled out, because they are where the principle
earns its place.

**The scheduler fails the test as usually written, and that is a real result.**
"The runqueue agrees with each thread's state" mentions the scheduler's structure
and every thread at once — the multiplicative shape exactly. A microkernel keeps
the scheduler inside on the grounds that it is mechanism; the locality test says
that is where the proof cost goes.

It can be restructured. Make *runnability* an affine grant: a thread's
transitions consume and produce a token, and the scheduler holds tokens for what
it considers runnable. "At most one Running per CPU" becomes a statement about
how many tokens the scheduler holds — local to the scheduler. Threads need no
invariant. Same move as the allocator, applied to a scheduling right instead of a
memory unit.

That is a design commitment, not a free lunch. It changes what a thread *is* in
the model, and it has not been tried.

**Device transfer isolation is the honest exclusion.** "No transfer target
overlaps privileged memory" is joint with the address-space plan by construction,
and no token discipline obviously fixes it, because both subsystems reason about
the same physical extent from different directions. It could be admitted by
passing the plan as an explicit input to every transfer decision, making the
obligation local at the cost of a wide interface. **OUT** until someone tries
that and can report the cost.

## 5. The data model

Thermite's current capability binds hardest here, so the constraint comes first.

### 5.1 The type universe is flat

A declared type may not appear inside another declared type — not as a struct
field, and not as an enum variant's payload:

```thermite
struct Regs  { ip: u64 }
struct Frame { regs: Regs, generation: u64 }        // error[E0425]
enum  Ev     { Header { r: Regs }, Done }           // error[E0425]
enum  Ev2    { Header(Regs), Done }                 // error[E0425]
```

All three fail identically. This is
[G4](language-gaps.md#g4-struct-fields-of-user-declared-types), reported as
[Thermite#122](https://github.com/dollspace-gay/Thermite/issues/122). That report
described it as a struct-field problem; measuring it against enums gives the true
scope: **the type graph must be one level deep.**

What remains expressible is genuinely useful:

- structs whose fields are primitives, carrying an invariant
- enums whose variants carry primitives, in tuple or record form
- functions over those, returning tuples of them

`enum Ev { Header { magic: u64, minor: u32 }, Done }` certifies at L3, so record
structure is available *inside enum variants* even though it is unavailable
across declarations. That is a real expressive resource, and the reason a
transition-system style works at all today.

### 5.2 What flatness costs, and why it costs a meso design more

**Shared record types.** If an execution context and a trap frame both carry a
register set, the fields are written out in both. There is no `Registers` to
share. Duplication is proportional to the number of interfaces.

**Type-level distinctions.** A physical and a virtual address are both `u64`, and
nothing stops one being passed where the other belongs, because the newtype that
would distinguish them is itself a declared type and cannot be a field. The
distinction moves into invariants as range predicates — `kind >= 1 && kind <= 6`
in place of an enum, naming conventions in place of types.

Both costs scale with the number of subsystems and interfaces between them. A
microkernel has few of each and pays once. **A meso design pays proportionally
more, so the flat universe is a harder constraint for Bulla than for a
microkernel.** That is not a complaint; it is why Bulla's design work produces
findings a microkernel's does not.

### 5.3 The decision

**Bulla designs the composed model.** The flat form is an *encoding* of it, not a
substitute, and the mapping is mechanical:

| composed | flat encoding |
|---|---|
| `struct A { b: B, … }` | inline B's fields into A with a `b_` prefix |
| `enum E { V(B) }` | `enum E { V { b_…: … } }`, B's fields inlined |
| a newtype over `u64` | a `u64` field plus a range predicate in the invariant |

The reasoning: an encoding produced by a stated rule can be re-derived when the
constraint lifts, whereas a design shaped around a limitation has to be
rediscovered. G4 is a defect in harness construction rather than a semantic
decision, so it is reasonable to expect it to lift.

The cost of being wrong is bounded. If G4 never lifts, Bulla has flat code with a
written rationale for its shape, which is what it would have had anyway.

**Status: NOT STARTED.** Blocker: G4 for the composed form. The flat encoding is
available now and is what any interim implementation uses, labelled as an
encoding.

## 6. The shape of a verified subsystem

Every subsystem in the core takes the same form:

```
step : State × Event → State × Action
```

State carries an invariant. Event and action alphabets are declared enums. `step`
is total and pure. Its obligations:

1. `I(s) ⟹ I(s')` — the invariant is preserved
2. a rejected event leaves authority-bearing state unchanged
3. every emitted action is authorised by the pre-state
4. action operands name live objects with matching generations

This is the same form TMK uses, arrived at from section 1 rather than adopted.
Independent convergence is mild evidence that it is the shape the language
affords.

## 7. Privileged operations: the core performs none

A verified kernel reaches the machine eventually. Two mechanisms, differing in
what they ask you to believe.

**A declared boundary** names a privileged operation, gives it a contract, and
binds it to one entry in a frozen registry. Callers are proved against the
contract; the body is *assumed* to satisfy it. The trusted base is the registry:
enumerable, readable, unproven.

**A capsule** carries the exact instruction bytes, a proof that executing them
from the stated precondition establishes the stated postcondition, and a
post-link check that the shipped image contains exactly those bytes. The body is
*proven*. This is TMK's mechanism and it is strictly stronger.

### The argument for a meso design

Boundaries do not scale the way this architecture needs. Each subsystem admitted
to the core brings privileged operations with it, so the registry grows with the
core. The trusted base would grow at the same rate as the verified core — which
is what `readable-trusted-base` exists to prevent, and what its recorded tension
against `it-actually-boots` already anticipates.

For a microkernel, `n` is small and the registry stays small. For a meso core,
"the trusted base is a list you can read in an afternoon" would quietly stop
being true.

**Decision: the verified core performs no privileged operations at all.**

The core is pure. It computes `(State, Action)` pairs, where an action is a
*description* of an effect — map this range, acknowledge this vector, resume this
context — and never performs one. An outside shell interprets the action alphabet
and performs the effects.

Consequences, plainly:

- **`#[boundary]` does not appear in Bulla's verified core.** The inherited
  architecture was built on it; this replaces that.
- The trusted base becomes the shell, bounded by the action alphabet rather than
  by the number of subsystems. A subsystem emitting only existing actions adds
  nothing to it.
- The core's claim closes at the action alphabet: *actions emitted are
  authorised*, not *effects performed are correct*. Whether the shell performs
  them faithfully is a separate obligation, and capsules are the eventual answer.
- Bulla is not building capsules. That is a machine-model investment TMK is
  making, and duplicating it would be waste.

This is the largest departure from the inherited architecture, and it is derived
from the meso choice rather than borrowed.

## 8. The assurance claim

Stated so that it reduces to per-clause tuples with named boundaries, as
[the assurance model](assurance-model.md) requires.

> Given the named toolchain, machine model, and shell assumptions, every accepted
> transition of the verified core preserves its subsystem invariant, changes no
> authority-bearing state on a rejected event, and emits only actions authorised
> by the pre-state and naming live objects with matching generations.

```
invariant preservation    all / complete / solver @ to_actions
rejection is inert        all / complete / solver @ to_actions
action authorisation      all / complete / solver @ to_actions
operand liveness          all / complete / solver @ to_actions
```

`to_actions` is a new boundary coordinate, and it is **weaker** than
`to_platform(p)`. It says the claim closes where the core emits a description,
and says nothing about what performing it does. That is the honest coordinate for
a core that performs no effects; inventing a stronger-sounding one would be the
failure this project exists to avoid.

### What it is not

- Not a claim that the shell performs actions faithfully. That obligation is
  unaddressed and has no mechanism proposed here.
- Not a claim about QEMU, OVMF, rustc, LLVM, Verus, Z3, or any physical CPU.
- Not a liveness claim. Affine types prevent duplicating a grant; nothing
  requires returning one, so resource exhaustion is outside the model.
- Not a concurrency claim. The model is sequential; two CPUs stepping one
  subsystem is outside it, and outside Thermite's expressiveness
  ([G2](language-gaps.md#g2-no-concurrency-semantics)).
- Not a claim about anything outside the core. The excluded subsystems in
  section 4 are unverified.

**Status: NOT STARTED**, every clause. There is no verified core. Blockers: G4
for the composed data model, an undesigned restructuring for the scheduler, G2
for concurrency.

## 9. What this needs from Thermite

| gap | why this architecture needs it | status |
|---|---|---|
| [G4](language-gaps.md#g4-struct-fields-of-user-declared-types) | the composed data model in §5; without it every interface is hand-duplicated | [#122](https://github.com/dollspace-gay/Thermite/issues/122) |
| [G1](language-gaps.md#g1-map-needs-remove-and-iteration) | ledgers and allocators need `remove` for revocation and free; schedulers and allocators need traversal | [#123](https://github.com/dollspace-gay/Thermite/issues/123) |
| [G2](language-gaps.md#g2-no-concurrency-semantics) | any claim covering more than one CPU | not filed; research |
| linear types | §3's grants prevent duplication but not leaks; a return obligation needs linearity | not filed; a language-design proposal, not a defect |

The last row is what this design surfaced. Thermite never claimed linear types,
so it is a requirement this architecture places on the language rather than a bug
to report.

## 10. What changed from the inherited architecture

The previous version described the platform layer, boundary registry, and
four-layer model Bulla forked. Three things invalidated it.

**The forked artifact is being withdrawn.** Upstream has said the kernel work
Bulla forked was an overshoot, to be replaced by the frozen primitives it was
meant to exercise. A document describing code that will not exist is worse than
none.

**The boundary registry does not suit a meso design.** §7. The inherited
architecture treated an enumerable trusted base as the central claim; for a core
admitting more subsystems, that base grows with the core.

**The data model was inherited from Rust, not designed for Thermite.** The plan
was to port `context.rs`. Attempting that port is what found G4, G4b and G6–G12,
and the reason it found them is that the source was shaped for a language with a
compositional type system. §5 designs for the language that exists, with a rule
for re-deriving when it improves.

What survives: the determinism properties, the reproducible container build, the
boot gate, and the evidence practice. Those are about how claims are checked
rather than what the kernel is, and they remain Bulla's strongest asset.

## 11. Relationship to Thermite-Microkernel

[TMK](https://github.com/dollspace-gay/Thermite-Microkernel) is a verified
microkernel by Thermite's author, further along in proof content: 2,649 lines of
Thermite across seven files, a five-level refinement chain with a record at each
arrow, and a release rule blocking `#[slag]`, proof holes, Forge L0–L2, Verus
`assume`, axioms, executable `external_body`, unverified assembly, and
`#[boundary]`.

Bulla is not a second one. The positions differ where §2 says: TMK is
structurally committed to keeping filesystems, network stack, process policy,
drivers and userland outside, and Bulla is investigating how much further in the
locality test lets a core reach.

That difference is the point rather than a rivalry. A microkernel's data model
never needs a type inside a type, so it never finds G4. It routes around `Map`'s
missing operations by keeping few maps. It avoids concurrency obligations by
keeping the core small. **A meso design meets those limits sooner and harder, so
the gaps it reports are ones the other design will not generate** — which makes
Bulla's contribution to the language rather than competition with the kernel.

Where Bulla is ahead is evidence *mechanism*: a digest-pinned reproducible build,
a cross-host determinism result, a six-scenario boot gate, a published artifact,
and `make` targets runnable with no agent tooling. TMK has 29 carefully scoped
evidence documents and no CI to regenerate them. The honest summary is that TMK
is ahead on proof content and Bulla is ahead on reproducibility.
