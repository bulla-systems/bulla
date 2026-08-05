---
{
  "v": 2,
  "cid": "bafyreif47kdlggb3l32fog5xk2xmdx3od33velsiqhxfbplrzrnanp2g4q",
  "sig": "77147bab1b253c6613c1e58ae7c7070abafd6e3d6d43dad886d390c27b3650c663cbb7d28aa6c990b74eb7ca8310300a705f6a33e4e5a2feab2e16be422d7648",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Observation",
  "cites": [],
  "rev": "223msbarrvvjq",
  "seq": 0,
  "of": 23,
  "text_len": 396,
  "content": "a764626f6479a16b4f62736572766174696f6ea16474657874606563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478286339653637323466623061323364663330646232623238666633396632316237353730633964366369776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b00065839af7ded8a"
}
---

Establish what the language actually affords by minimal reproduction rather than by reading its reference. Every claim about a capability is a three-line file and a checker verdict. This is the atom that has repeatedly contradicted the documentation, in both directions.

```day-atom
{"in":["language-question"],"out":["language-fact"],"next":["architecture-design"],"done":["gap-register"]}
```

---8<---
---
{
  "v": 2,
  "cid": "bafyreibgdiqmejdpcgjjscflo773trls4e26ihbr2ida7ar7s67yt5hwh4",
  "sig": "616ad04390be265182da7fddbfd0cdbdf8a213ec2dd4095e857b5f5e38d363027e1933b3c6306c94499789542e895e99fe0107455ee61404f04dd6bccb933100",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Observation",
  "cites": [],
  "rev": "223msbat4rehr",
  "seq": 1,
  "of": 23,
  "text_len": 263,
  "content": "a764626f6479a16b4f62736572766174696f6ea16474657874606563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478286339653637323466623061323364663330646232623238666633396632316237353730633964366369776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b00065839b22ba949"
}
---

G4 constrains user-declared types only. Vec<u64> and Map<u64,u64> are fine as struct fields and enum payloads, both L3. So the type universe is flat with respect to declarations, not with respect to structure, which is materially less binding than first recorded.
---8<---
---
{
  "v": 2,
  "cid": "bafyreig6dqx6betbsus2mstj7txsweqltl4vgjz5fcqmodjiilhzv3rfcq",
  "sig": "72ec62e96f0bb66419ca3ac08727b5542dbd9a7fe19e1bcdc00533f15e4c414a5e6edef90d46228f267e7c0d06ee11f3142384b5400d130ef9410fe887f771aa",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Observation",
  "cites": [],
  "rev": "223msbat4wozc",
  "seq": 2,
  "of": 23,
  "text_len": 481,
  "content": "a764626f6479a16b4f62736572766174696f6ea16474657874606563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478286339653637323466623061323364663330646232623238666633396632316237353730633964366369776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b00065839b22e537a"
}
---

The spec surface of structured data is incomplete in four ways: a recursive spec fn over an ADT has its bool return rewritten to nat; Vec indexing in spec emits xs@ needing a View the wrapper lacks while spec_get already exists; combinators are not woven into the inv harness though user spec fns are; and spec closures fail in value position though user spec fns work there. Slices have a working spec surface, which is what shows the wrappers are unfinished rather than intended.
---8<---
---
{
  "v": 2,
  "cid": "bafyreidgu7cq7vgriycfot3jigm662upm6bgmyy34odoscvr64m2b33cpe",
  "sig": "15d51905409aa01832d1142c3c6bab1d47b02b54434655a2e1e04ff470b96a433a4860bf6147aa2187d4b11bc8b2b63b8c8a0b6e9e8295da7d060fd82d4e6c93",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Observation",
  "cites": [],
  "rev": "223msbat544i5",
  "seq": 3,
  "of": 23,
  "text_len": 426,
  "content": "a764626f6479a16b4f62736572766174696f6ea16474657874606563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478286339653637323466623061323364663330646232623238666633396632316237353730633964366369776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b00065839b2310959"
}
---

The pinned Verus already ships the concurrency metatheory: tokens.rs for linear ghost state, atomic_ghost.rs, invariant.rs, rwlock.rs, thread.rs, state_machines_macros. So concurrency for Thermite is surface syntax over existing machinery rather than new semantics. Caveat from tokens.rs itself: the macro creates trusted implementations and their properties are assumed, which a release rule blocking axioms must reckon with.
---8<---
---
{
  "v": 2,
  "cid": "bafyreih23zekvytg6odtlqi4rdpimabdcyy5ttn7lj2z5ahk6plkalexzi",
  "sig": "f24a4bd95d90bfb0d5a7bbae0e70d98afa4d087815fa9cc040385b9a9a0bbaa569365d5f8ed2840290ab09ddfcc767dcd1219ea8ab9b8a057490d7d9a61cb7f4",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Publication",
  "cites": [],
  "rev": "223msbat62abp",
  "seq": 4,
  "of": 23,
  "content": "a764626f6479a16b5075626c69636174696f6ea1656c6179657267476974547265656563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478286339653637323466623061323364663330646232623238666633396632316237353730633964366369776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b00065839b240188b"
}
---
---8<---
---
{
  "v": 2,
  "cid": "bafyreibgnwbotpl4zlzgemefu2bsgr2f6ayagc47zpoj7buabpdwykmj2u",
  "sig": "bdbb61ae8a069e1fcf13475406488c8f84a94020ed7dc9dbffaec2054a6e45b34536b938d97a7208eae556b041f621ec8f5ae8d47b5255029adf9ca99e5fcd8d",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Result",
  "cites": [],
  "rev": "223msbatuk56v",
  "seq": 5,
  "of": 23,
  "text_len": 464,
  "content": "a764626f6479a166526573756c74a16474657874606563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478286339653637323466623061323364663330646232623238666633396632316237353730633964366369776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b00065839b3a80c31"
}
---

Ran throughout the session. Established by minimal reproduction: G4's true scope (any position, enums included, user-declared only), the four spec-surface defects, that declared types are affine, that recursive structures certify, that Verus ships the concurrency machinery. Contradicted the reference in both directions — it understated what works (Vec fields, recursive spec fns) and overstated it (spec fns described as executable are not callable from exec).
---8<---
---
{
  "v": 2,
  "cid": "bafyreiglqhbgveu7iz2rfadqqxxva2bye5yc3sltq3jvwewz44i2c6znhq",
  "sig": "b685e4b2169f2a2552842bf5c8da365992f176b2fb9aeb73e1696698897a49ca53169d0c8f9142a6dc7810efdebc58408b4fa47f45c4a078d074eeb3ed9b0a7c",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Publication",
  "cites": [],
  "rev": "223msbatvajts",
  "seq": 6,
  "of": 23,
  "content": "a764626f6479a16b5075626c69636174696f6ea1656c6179657267476974547265656563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478286339653637323466623061323364663330646232623238666633396632316237353730633964366369776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b00065839b3b33ec8"
}
---
---8<---
---
{
  "v": 2,
  "cid": "bafyreiejpjxi2wkolshwobcbeieemyu7bhnubfaqxbeajghe6azl2xgcym",
  "sig": "d4f2d630d7acf9c792721842f94208d6849222aabeb6ecd88cb2fb1b2d58aeda43caa6fedd76f18fad26f9b6cd1dbd0d875544b65317d7902a0854bc3707a120",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Publication",
  "cites": [],
  "rev": "223msbauy3r4h",
  "seq": 7,
  "of": 23,
  "content": "a764626f6479a16b5075626c69636174696f6ea1656c6179657267476974547265656563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478286339653637323466623061323364663330646232623238666633396632316237353730633964366369776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b00065839b5e0dbe6"
}
---
---8<---
---
{
  "v": 2,
  "cid": "bafyreibei5oi5n2acikg3bvxao3q4z3ojle4rorgj6xayah5pxgntvjec4",
  "sig": "619920c451c37610f36995a1e2a86346234be7c6408b6b57cd139daf7938c74766b91530cba6446a82cd208ba6e8b8a9d0fe674b1f87ab9b1d1b7c3c978c48e2",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Observation",
  "cites": [],
  "rev": "223msc6dxctgb",
  "seq": 8,
  "of": 23,
  "text_len": 299,
  "content": "a764626f6479a16b4f62736572766174696f6ea16474657874606563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478286366643838656536613430353464623464386133343832653139663230376334323965353230663969776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b0006584113d46510"
}
---

Thermite has no assert, no proof blocks and no ghost statements — verified zero occurrences. So proof granularity is necessarily per-obligation or per-function; there is no way to interleave proof steps in a body. That is what settles opacity discharge as a by-clause hint rather than a statement.
---8<---
---
{
  "v": 2,
  "cid": "bafyreifzhy4bppjo3gxpbkcpqo7jws6ijojjfrzdwfmyjru3ucjd5gnkgy",
  "sig": "4f9b5fe70520eb79cdc14fc925d9515406e1995e04720b9ad2f2b823ea1cc82064a536b21ca867b1af310ce39bedf1aa1420799edd745c45867fdb2ec559fa19",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Publication",
  "cites": [],
  "rev": "223msc6dy4ofr",
  "seq": 9,
  "of": 23,
  "content": "a764626f6479a16b5075626c69636174696f6ea1656c6179657267476974547265656563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478286366643838656536613430353464623464386133343832653139663230376334323965353230663969776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b0006584113e150ff"
}
---
---8<---
---
{
  "v": 2,
  "cid": "bafyreie3dvffe7o4eqazosdjwil6pq3q5bdh66rn5kkmdizyzroes72tnq",
  "sig": "f32a3c4b053c2a0d6f0a357db4b80f8b348b10a978774d1f9e0752db7d52d07d1368e587a3a91855d973db7eb5952cc2543d93e4be6a59fb49ce0cb247d96cf3",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Decision",
  "cites": [],
  "rev": "223mscg6y3xxk",
  "seq": 10,
  "of": 23,
  "text_len": 820,
  "content": "a764626f6479a1684465636973696f6ea16474657874606563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478283964396363326538353538663236343932623431363034666631303339303565613364373434346569776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b0006584309e0f73a"
}
---

The linearity keyword is 'resource', not 'once' or 'linear'. Two filters decided it: the keyword should name the half Rust's move semantics do not already give, which is the silent drop rather than duplication; and the modifier slot is an adjective slot (pub struct, unsafe fn, opaque spec fn), where every candidate describing what happens TO the value lands as an adverb or a past participle. 'resource' names what the value IS, the move 'shared' already makes for state, and both halves follow from the kind: a copy is a second claim on the same thing, and a resource you fail to release is a resource leak. Rejected: linear (mathematics not property), once (std::sync::Once, and an adverb), used (Rust #[used]), consumed/spent/owed (past participle), accountable/owing/custodial (relational), undroppable (negation).
---8<---
---
{
  "v": 2,
  "cid": "bafyreify2b3flwtlzplf6qfcedilc5ekgjhi66b3hlz4pfkttjgzkltwf4",
  "sig": "c55bf2f94f85bb081e07c51725ae6aebb2128d19cc662fdcef088b72313871e80052291eec4a4fcfc0b411a3bc0c7767fdd42c19e2a693bb021f645187158af5",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Decision",
  "cites": [],
  "rev": "223mscg6ydbfq",
  "seq": 11,
  "of": 23,
  "text_len": 790,
  "content": "a764626f6479a1684465636973696f6ea16474657874606563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478283964396363326538353538663236343932623431363034666631303339303565613364373434346569776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b0006584309e49d01"
}
---

The termination measure is 'measures M', with a comma list for a lexicographic measure. 'terminates by' is impossible on mechanism: a clause keyword is also a semantic-address segment, validate_segments splits on '.' against an allowlist, and a space-bearing segment is rejected as malformed before lookup while dec/ens/req resolve as well-formed. 'by' is separately reserved for proof hints, so 'terminates by M' and 'ensures P by unfold(f)' would use one token in two roles in adjacent clauses. 'exhausts' collides with 'resource' once linearity takes that word, since resource exhaustion is the liveness property this project does not claim. Near-miss recorded: 'variant' is the textbook dual of 'invariant' and Eiffel uses both as keywords, but it already means one arm of an enum here.
---8<---
---
{
  "v": 2,
  "cid": "bafyreigyykhgrqqpnzbclkg65gbwqxqa6jtie4mvu6hlfem3urfoadx7ze",
  "sig": "21c0a582dcd25b4bbc94d2c944bb7a7c18202c8cb4356d5c8cd86f7eeeb60d3c7896098a0116418b7c040642eb96e0730d1ef1241b494b18184ea231e09375ba",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Decision",
  "cites": [],
  "rev": "223mscg7iyimq",
  "seq": 12,
  "of": 23,
  "text_len": 737,
  "content": "a764626f6479a1684465636973696f6ea16474657874606563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478283964396363326538353538663236343932623431363034666631303339303565613364373434346569776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b000658430aef39e0"
}
---

Every clause is a third-person-singular verb whose subject is the item, so a clause reads as a sentence with the subject elided. This is a rule rather than a preference and it decided several names: invariant becomes 'keeps', the crash clause becomes 'survives', and the concurrent block becomes 'interleaves'. The tell that the rule is right is that requires, ensures, asks and promises already obey it and the one clause that does not is 'inv', which was inherited rather than chosen. Three exemptions, each explained by the rule rather than excused: the effect row is not a sentence the item asserts because () ! pure and () ! write(shootdown) are different types; block headers take no predicate; modifiers are adjectives on an item.
---8<---
---
{
  "v": 2,
  "cid": "bafyreibe4x7bc3jwo367erorjezxhacglmtzbd4tklxdku5w7jinjp33h4",
  "sig": "d9bb3736553929e93b1f84667cd72035a61dc9969feceb40f799f039d461006637bdc1be0ab6bcd32595e457f4c1a88a608a0a77d9a75583f96f90be9edd21ad",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Decision",
  "cites": [],
  "rev": "223mscg7j7pqy",
  "seq": 13,
  "of": 23,
  "text_len": 576,
  "content": "a764626f6479a1684465636973696f6ea16474657874606563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478283964396363326538353538663236343932623431363034666631303339303565613364373434346569776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b000658430af2d666"
}
---

A clause body is a block of conjuncts with the bare single-expression form as sugar: requires { a; b; } and requires n < 100. This buys per-obligation 'by' hints, since a conjunct is an obligation, and it closes a gap already present upstream: validate_segments accepts req#k and ens#k ordinals while parse_contract takes exactly one req, so the address layer was built for a clause with numbered parts and the parser never grew them. 'measures' is the exception and preserves the rule, taking a comma list because a lexicographic measure is ordered rather than a conjunction.
---8<---
---
{
  "v": 2,
  "cid": "bafyreifq4b3kmevluo6wfcmb4nbyd7iakpr72ogpnz3yx7mamihgsbmkli",
  "sig": "6b6db5edae5ec54eefa500894493aabf055e1d616b1a1f83fb0c2fa5925ad46e38bf8bec0a6e2d5425269154840952e9f2e6894812d2146d76707d9de8d5b2ac",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Decision",
  "cites": [],
  "rev": "223mscg7jgq5h",
  "seq": 14,
  "of": 23,
  "text_len": 613,
  "content": "a764626f6479a1684465636973696f6ea16474657874606563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478283964396363326538353538663236343932623431363034666631303339303565613364373434346569776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b000658430af657f7"
}
---

Trivial clauses are spelled 'nothing' everywhere and 'anything' leaves the language. Under the clause grammar 'f requires anything' is not a sentence anyone means; the intended sense only survives under negation. The earlier asymmetry (requires anything / ensures nothing) was carrying the direction in the object, and the verb already carries it. It also removes an inversion hazard: 'asks anything' could read as demanding everything of the environment, the inverse of the intended meaning, which would license a vacuous proof. The dangerous case keeps no sugar and is written 'requires false' with the literal.
---8<---
---
{
  "v": 2,
  "cid": "bafyreifhktayh6msjkumo7gqj25a5ueghtvuz3l547yo6y4zmaczp533ti",
  "sig": "7bdea0f96cb698ed5505225518e629f303183734ba25bc2406a65d8d884eb2400f4d771796ca3073c486a957795578dd15fea8011b1cf10b78ceb609f7999f4b",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Decision",
  "cites": [],
  "rev": "223mscg7x7avw",
  "seq": 15,
  "of": 23,
  "text_len": 884,
  "content": "a764626f6479a1684465636973696f6ea16474657874606563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478283964396363326538353538663236343932623431363034666631303339303565613364373434346569776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b000658430bd29aff"
}
---

The effect row is two families of label, and an effect label is three things: a name, the kind of argument it takes, and how two of them combine. State effects always name a region (read(r), write(r)) and compose by union; control effects describe the arrow (panic, blocks, diverge, cost(E)) and compose by or, or by sum for cost. The shape is the discriminator. The line between the row and the clauses is that an effect propagates up the call graph by construction while a clause is proved at the item, which is why cost belongs in the row and why the row belongs to the arrow. Consequences: alloc, time and rand are shared state with the name suppressed and become write(heap), read(clock), write(entropy); 'channel' carried no information because ownership already gives exclusivity, and its honest content is that the function can wait, so it becomes the control effect 'blocks'.
---8<---
---
{
  "v": 2,
  "cid": "bafyreiagircxzpwmctkd7whbq4umhyamvuqzdq7y66gjee46vd7kfejwpi",
  "sig": "ff68344da918838d624759b60ddc6dfabff92b568d02ca9c3358c38f4c2ed74e4a569f397a14d31245ee293191c055984da98bfc5ed4143188e290dcd829008b",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Decision",
  "cites": [],
  "rev": "223mscg7xh2ex",
  "seq": 16,
  "of": 23,
  "text_len": 680,
  "content": "a764626f6479a1684465636973696f6ea16474657874606563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478283964396363326538353538663236343932623431363034666631303339303565613364373434346569776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b000658430bd680e7"
}
---

Which effects name their resource: a 'shared' thing is named in the row, a 'resource' thing is not, because ownership already gives exclusivity. This replaces 'the effect row names what the signature does not', which fails to discriminate the case it was written for, since acknowledge(s: &mut Shoot, cpu: u64) also takes the shared state as a parameter and &mut Shoot names a type rather than an identity in the same way c: provides PageRequest does. The replacement also absorbs a caveat the old rule had to state as an exception: if an endpoint were reachable from global state the rule keeps working, because the thing reached is shared and the shared item is what gets named.
---8<---
---
{
  "v": 2,
  "cid": "bafyreifdc7tyu2frtq5pwh3wmgcepadjdzcnigdqqe5s463qcse7k5wb7a",
  "sig": "ddd144854f88f51b558d613a2033457ae0675aa52286bc1acf468407bfe1bb5c7a946a03566d42a30e76dfd1ac57b684e7ef23b52b6c16846fc4d89ee04abb22",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Observation",
  "cites": [],
  "rev": "223mscg7xo2yc",
  "seq": 17,
  "of": 23,
  "text_len": 631,
  "content": "a764626f6479a16b4f62736572766174696f6ea16474657874606563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478283964396363326538353538663236343932623431363034666631303339303565613364373434346569776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b000658430bda0350"
}
---

Reproduced at the pin against Verus 0.2026.05.24.ecee80a. The effect row is unchecked in both directions: fx write(a_resource_that_does_not_exist), read(nor_this_one) on a body that touches nothing certifies L3, so an undeclared name passes and an unperformed effect passes. Clause order is enforced with a structured error: ens before req, fx first, and a second req after ens all fail with 'clause req is out of order in f'. The enforced order today is req x1, ens x1+, fx x1 last, so moving the effect row to the front is a breaking reorder of every existing .th, which the surface-conventions document did not previously state.
---8<---
---
{
  "v": 2,
  "cid": "bafyreignow24antecoru2wyoiy334bxgevlldvmvdl6eb7gmna4iokdrzi",
  "sig": "a4fc38ee3070f817fac4a65dc983e19c6ee7238932ee947249f7b114cb2addc35035e26470affa8c3bbbcaf21d23a8270ae5533db6da583f9c361d0eb8214169",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Observation",
  "cites": [],
  "rev": "223mscglcgg53",
  "seq": 18,
  "of": 23,
  "text_len": 934,
  "content": "a764626f6479a16b4f62736572766174696f6ea16474657874606563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478286535333134366232313664386530663165626665613734383164393336343264396634363261333869776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b0006584322862fea"
}
---

G12 corrected: the mutation-equivalence scalar restriction is a bar, not a bias. A matched pair isolates the return type as the only difference. Both bodies have identical branches, so every mutation of the if condition is observably equivalent and none is evidence of a weak contract. Scalar return: 1/1 killed, non-vacuous. Result<Struct,_> return, same body shape and same contract strength: 0/4, VACUOUS - WeakContract, with the survivor naming 'equivalence probe Unsupported - survivor COUNTED, not excluded'. The denominators carry it: the same operators generate the same mutants, the scalar contract is scored against 1 and the struct against 4, and the three the scalar run drops are the ones its equivalence probe proved equivalent. The reported remedy - strengthen the ens - is unavailable, since no postcondition distinguishes bodies that cannot be distinguished. Reproduced independently on src/context.th resume at 9/18.
---8<---
---
{
  "v": 2,
  "cid": "bafyreibqwaf5s4it3l4g4ack6tumcez5bcgx64wzwkpsxb637vbfzceq7u",
  "sig": "2fe7dab9e2eddedfb916483b56239eb85f110af92537207c93b1f24af0d9f2305ac92ae9c253eb5d7156778e9679789128d15f1ac3ec5feb148b71b022d81481",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Observation",
  "cites": [],
  "rev": "223mscgzwvica",
  "seq": 19,
  "of": 23,
  "text_len": 1288,
  "content": "a764626f6479a16b4f62736572766174696f6ea16474657874606563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478286439366538646336613934623766323966353537353930663235376563336566383363363366313969776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b000658433fcdb889"
}
---

Two breaks measured for the effect-rows migration. First, the corpus: across 67 .th files at the pin there are 149 effect atoms - 93 pure and 6 diverge unaffected, 22 alloc and 4 time and 3 term needing rewrite to named regions, and 24 atoms carrying 7 distinct resource names (clock, db, input, log, memory, output, stdin) every one of which is declared nowhere because declaring one is what the RFC adds. So 50 of 149 change, and a compiler-injected prelude for the ambient names plus one declaration line per program covers all of them. Second, the kernel target refuses the RFC's central example: forge build --target kernel rejects fx write(shootdown) as 'the ambient-syscall effect write(shootdown) (a write userspace syscall)', admitting only pure/alloc/panic/diverge, because KERNEL_REJECTED_FX matches the leading verb of each token. The same file with alloc builds. So turning alloc into write(heap) would flip the one allocation effect the kernel target admits into a rejected one. Both facts have one cause the RFC removes: the row cannot distinguish a syscall-backed ambient effect from a state effect on declared state, so the profile has to reject by verb. Declared regions let it reject by region kind instead, which is a required companion change rather than a follow-up.
---8<---
---
{
  "v": 2,
  "cid": "bafyreigat23uokblej7paliq24cbppoxjc54lxfsw5xinwcian2gagcs7i",
  "sig": "15f767637f0215faec27bf4cd00ed2bd28d54cc300e2850540964214f0dc50eb50e6a5e737931d9dda032e6fff2cc3d353181c01727f4a4bb37ceb42622634ec",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Publication",
  "cites": [],
  "rev": "223mscphlr7xb",
  "seq": 20,
  "of": 23,
  "content": "a764626f6479a16b5075626c69636174696f6ea1656c6179657267476974547265656563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478286532306336613661393866316235643939346563626134353133353065666638306530313034663369776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b000658455b1b9735"
}
---
---8<---
---
{
  "v": 2,
  "cid": "bafyreibsqt4tahldqyzxuhl2z6ovy6kiy62jv2kfdk2h3kqotjwbrpdkfm",
  "sig": "6a33f761ca4c4fb3b9591417424b206c4b6ef9010a279ba3392da9080d1c3bdd4d957201c7f5f4ffb710d1a35d9a45a46840d8378f4e54f7a9d1d5937a06b175",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Observation",
  "cites": [],
  "rev": "223msd2evofsh",
  "seq": 21,
  "of": 23,
  "text_len": 1191,
  "content": "a764626f6479a16b4f62736572766174696f6ea16474657874606563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478283839653563396661386266663661346166633934303338323534356338663137626130313664326569776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b0006584815ba2e9d"
}
---

The resumable-step shape certifies at L3 today, which closes a proposal from the previous session that never reached a document. enum Walk { Ready { addr: u64 }, Pending { level: u32, index: u64 } } plus fn advance(s: WalkState) -> Walk with a match over the variants in ens: both items L3 at the pin. The operation's resumption point is data the caller holds rather than a program counter in a suspended frame, and the postcondition carries a measure across calls (level < s.level), so the walk terminates across calls and not merely within one. This is async's shape without async's mechanism: an async fn's states and resume points exist only in generated code, which is why the pinned Verus ships vstd/future.rs as 45 lines of uninterp stubs. Constraints: no user generics so Step<A> is monomorphised per operation (G3); enum payloads are primitives so a continuation is a flat record (G4); and variant paths must be qualified in a contract. The unqualified form fails with error[E0422] reported as a harness-construction fault - 'the harness construction is wrong (a missing woven decl)' - when the cause is in the source, which names the wrong place in the same way G12's message does.
---8<---
---
{
  "v": 2,
  "cid": "bafyreiga4xakfyozs6ssfrbfvn2j2xhciin4obaza7khipsdzfpm4hy2xy",
  "sig": "9d2aa7de13ef0185460078d75a5f3cf3adda4ad83c916956056458933fbab8da187d72b00cfdd633279e208a3bb6e11d1f3bf07a0efa55b757b8fd8d9324cc45",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"atom/language-probe\")",
  "kind": "Publication",
  "cites": [],
  "rev": "223msd2f6ncja",
  "seq": 22,
  "of": 23,
  "content": "a764626f6479a16b5075626c69636174696f6ea1656c6179657267476974547265656563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c7361746f6d2f6c616e67756167652d70726f62656961727469666163747381a166436f6d6d697478286336313162643562326634306463633463363435383964373636343337313634363061353231663869776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b000658481649a17c"
}
---
