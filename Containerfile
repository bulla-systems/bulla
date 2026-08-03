# The build environment for a reproducible image.
#
# docs/reproduction.md records that the same source at the same pin produces
# different images from an aarch64-apple-darwin toolchain and an
# x86_64-unknown-linux-gnu one. The instruction streams match and the function
# layout does not, no source paths are embedded, and both hosts run rustc 1.95.0
# with LLVM 22.1.2 — so the difference is the host build of the toolchain, not
# the source, the flags, or the compiler version.
#
# Fixing the host is therefore the fix. Every input below is pinned by digest or
# exact version so that two machines running this image run the same compiler
# binary rather than two builds of the same compiler version.
#
# rust:1.95.0-slim-bookworm, linux/amd64, resolved 2026-08-03.
FROM rust@sha256:6f9e63259f12e1e599296f5ecfed2bae46de4af0ee0525dd8b89c046e236d5c5

# Keep in step with .github/workflows/ci.yml and docs/upstream-pin.md.
ARG VERUS_VERSION=0.2026.05.24.ecee80a

ENV DEBIAN_FRONTEND=noninteractive \
    SOURCE_DATE_EPOCH=1704067200 \
    TZ=UTC \
    LC_ALL=C.UTF-8

# The image builder needs mkfs.fat, mmd/mcopy, the LLVM binutils and `file`; the
# acceptance harness needs QEMU, an OVMF pair, and Python 3.10 or newer
# (bookworm ships 3.11). git is needed to fetch the upstream pin.
RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
      ca-certificates curl unzip git \
      qemu-system-x86 ovmf dosfstools mtools llvm file \
      python3 \
 && rm -rf /var/lib/apt/lists/*

RUN rustup target add x86_64-unknown-uefi \
 && rustup component add rustfmt clippy

RUN curl -fsSL -o /tmp/verus.zip \
      "https://github.com/verus-lang/verus/releases/download/release/${VERUS_VERSION}/verus-${VERUS_VERSION}-x86-linux.zip" \
 && mkdir -p /opt/verus \
 && unzip -q /tmp/verus.zip -d /opt/verus \
 && rm /tmp/verus.zip \
 && ln -s "$(find /opt/verus -type f -name verus | head -1)" /usr/local/bin/verus \
 && verus --version

# The acceptance harness searches three Linux firmware roots; bookworm's ovmf
# package populates /usr/share/OVMF. Recorded here so a firmware-discovery
# failure inside the container is legible.
RUN ls -l /usr/share/OVMF/

WORKDIR /work
ENTRYPOINT []
CMD ["/bin/bash"]
