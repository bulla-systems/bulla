# Every trust-bearing check in this repository is a target here and runs in CI.
# Editor hooks and agent tooling, if any, shell out to these targets rather than
# reimplementing them. See CONTRIBUTING.md.

IMAGE ?= dist/bulla.img

.PHONY: all image image-container verify determinism boot-matrix check-fork check clean

all: check

## check-fork: every forked file matches the upstream pin, or is a declared divergence
check-fork:
	./scripts/check-fork.sh

## image: build the bootable image from the forked tree via forge at the pin
image:
	./scripts/build-image.sh $(IMAGE)

## verify: re-check the receipt binding both closures to the image
verify:
	./scripts/verify-image.sh $(IMAGE)

## determinism: build twice and compare the images byte for byte
determinism:
	./scripts/check-determinism.sh

## boot-matrix: nominal 1/2/4/8 CPUs, AP-start-failure, and reboot under QEMU/OVMF
boot-matrix:
	./platform/x86_64-pc-uefi-smp-v1/test-qemu.py $(IMAGE) --output-dir dist/boot-evidence

## image-container: build inside the pinned container, so the digest is host-independent
image-container:
	./scripts/build-in-container.sh $(IMAGE)

# determinism builds twice and leaves the second image in place, so it stands in
# for `image` here rather than adding a third build of the same tree.
check: check-fork determinism verify boot-matrix

clean:
	rm -rf dist .build .build-container
