---
{
  "v": 2,
  "cid": "bafyreibcgkas64oc7rll3ugbekynd3lxymsyxajnnn6sa3vmwc4wfpry3m",
  "sig": "a71781766e14fcae32713ba03620bc590a7bed465033f47cb14b880d8bd5abb67c3ab2e65de4ec053bbd71bf597c7a0d17013771db0da5062e08e550c2ef8803",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"schema/witness\")",
  "kind": "Observation",
  "cites": [],
  "rev": "223ms5fxdkmv6",
  "seq": 0,
  "of": 5,
  "text_len": 614,
  "content": "a764626f6479a16b4f62736572766174696f6ea16474657874606563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c6e736368656d612f7769746e6573736961727469666163747381a166436f6d6d697478286633346261353836636465626432393631353263323963613336633565643461663431306438636169776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b0006581afa984ae6"
}
---

Witness types for Bulla. Each names a class of artifact that would evidence a
telos or an atom's completion — types, not instances.

```day-witness
{
  "upstream-pin": {"path": "docs/upstream-pin.md"},
  "bootable-image": {"path": "dist/*.img"},
  "build-receipt": {"path": "dist/*.receipt"},
  "boot-evidence": {"path": "dist/boot-evidence/*.json"},
  "published-artifact": {"tag": "v*"},
  "run-doc": {"path": "docs/running.md"},
  "verified-source": {"path": "src/*.th"},
  "trusted-base-inventory": {"path": "platform/x86_64-pc-uefi-smp-v1/registry.toml"},
  "status-table": {"path": "docs/roadmap.md"}
}
```
---8<---
---
{
  "v": 2,
  "cid": "bafyreihkj2akd2uqprcnm2hw5pzmlm2ljpufokayd4odxio3tjgmimjpg4",
  "sig": "7a5dba7c3abbed0313cd74b025adb78392087a86586cc6dea4fcd5a33095c65b66b6fd466424764b41b32b3ae02dbc6ae52a6316ae5f005de8aadcf1774141c4",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"schema/witness\")",
  "kind": "Observation",
  "cites": [],
  "rev": "223ms5gs65ekw",
  "seq": 1,
  "of": 5,
  "text_len": 770,
  "content": "a764626f6479a16b4f62736572766174696f6ea16474657874606563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c6e736368656d612f7769746e6573736961727469666163747381a166436f6d6d697478286633346261353836636465626432393631353263323963613336633565643461663431306438636169776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b0006581b3041a91b"
}
---

Witness types for Bulla. Each names a class of artifact that would evidence a
telos or an atom's completion — types, not instances.

Revised: boot evidence is written by test-qemu.py as `boot-<cpus>[-scenario].log`,
not JSON. The earlier declaration named a pattern nothing produces.

```day-witness
{
  "upstream-pin": {"path": "docs/upstream-pin.md"},
  "bootable-image": {"path": "dist/*.img"},
  "build-receipt": {"path": "dist/*.receipt.json"},
  "boot-evidence": {"path": "dist/boot-evidence/*.log"},
  "published-artifact": {"tag": "v*"},
  "run-doc": {"path": "docs/running.md"},
  "verified-source": {"path": "src/*.th"},
  "trusted-base-inventory": {"path": "platform/x86_64-pc-uefi-smp-v1/registry.toml"},
  "status-table": {"path": "docs/roadmap.md"}
}
```
---8<---
---
{
  "v": 2,
  "cid": "bafyreibwvrbxhvvz5bbvidgsobhbxcpfz3by2usdbfhzwhgqbrs2jivamy",
  "sig": "ba4a3c7f1dc6685c7e33cd231670c2c07d8fd5abb47d83ae5b7873c8fb7e1dbc2a1fd1056ef0699398b801cdeeb0e8b248b4522da0ac1eb089c9f761c276a7e6",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"schema/witness\")",
  "kind": "Observation",
  "cites": [],
  "rev": "223ms5hadhzna",
  "seq": 2,
  "of": 5,
  "text_len": 1010,
  "content": "a764626f6479a16b4f62736572766174696f6ea16474657874606563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c6e736368656d612f7769746e6573736961727469666163747381a166436f6d6d697478286633346261353836636465626432393631353263323963613336633565643461663431306438636169776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b0006581b4c96fdf1"
}
---

Witness types for Bulla.

Revised twice. The first map probed `dist/*.img` and `dist/boot-evidence/*.log`
by path, but day's path probes see tracked files, and build outputs are
gitignored — a 64 MiB image does not belong in git. Those witnesses could never
be met, which makes them decoration rather than evidence. Artifact-shaped
witnesses are command probes; document-shaped witnesses are path probes.

```day-witness
{
  "upstream-pin": {"path": "docs/upstream-pin.md"},
  "reproduction-record": {"path": "docs/reproduction.md"},
  "run-doc": {"path": "docs/running.md"},
  "status-table": {"path": "docs/roadmap.md"},
  "verified-source": {"path": "src/*.th"},
  "trusted-base-inventory": {"path": "platform/x86_64-pc-uefi-smp-v1/registry.toml"},
  "bootable-image": {"command": "test -s dist/bulla.img"},
  "build-receipt": {"command": "test -s dist/bulla.receipt.json"},
  "boot-evidence": {"command": "test -n \"$(ls -A dist/boot-evidence 2>/dev/null)\""},
  "published-artifact": {"tag": "v*"}
}
```
---8<---
---
{
  "v": 2,
  "cid": "bafyreihlluh5s35ejj46lfhi7utfdsi7fqbvmw4zsecm674m2dx6pvh4my",
  "sig": "11e0d8a882104a492761f482864812b414c161aa7834272f683659f754f41c34740d24a15abd74ceebe97bee5c1fc0ed6fef142e8c6324af9ea2f3e1347775fb",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"schema/witness\")",
  "kind": "Publication",
  "cites": [],
  "rev": "223ms5hbdqfo4",
  "seq": 3,
  "of": 5,
  "content": "a764626f6479a16b5075626c69636174696f6ea1656c6179657267476974547265656563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c6e736368656d612f7769746e6573736961727469666163747381a166436f6d6d697478286633346261353836636465626432393631353263323963613336633565643461663431306438636169776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b0006581b4e9b2e0b"
}
---
---8<---
---
{
  "v": 2,
  "cid": "bafyreieubcgiizsn3tcbde47imkkv4lhzs5gvxrgpm7apf5pmtmf7u6ksa",
  "sig": "cb5e0e9eb587f882f7e6dd696524db4c9dc3ebfcc84341080c4923263fbf14e9463a221e9559095699829887d2193fde7ad7ce81845073e3c9722d50306a519c",
  "author": "did:key:zDnaetDEzdwnPyn7iTx9FyFPxJDK6f9npD9HNjUfVsgHBky6w",
  "subject": "Local(\"schema/witness\")",
  "kind": "Publication",
  "cites": [],
  "rev": "223ms5hy4p3ln",
  "seq": 4,
  "of": 5,
  "content": "a764626f6479a16b5075626c69636174696f6ea1656c6179657267476974547265656563697465738066617574686f72a26364696478396469643a6b65793a7a446e61657444457a64776e50796e376954783946794650784a444b3666396e704439484e6a556656736748426b793677656167656e74f6677375626a656374a1654c6f63616c6e736368656d612f7769746e6573736961727469666163747381a166436f6d6d697478283764356665306365373337303139383235653061346662333464643430316133396239383164666169776f726b7370616365a169576f726b73706163657840313665613136383039343065656230623635383838386264366365353465343833326663653165623164333265303665633937353431333930636235353862656b7265636f726465645f61741b0006581b7c2a85ca"
}
---
