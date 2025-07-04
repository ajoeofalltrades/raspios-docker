# Raspberry Pi OS Bullseye & Bookworm → Docker

*(multi‑arch **plus** x86 QEMU‑layered)*

Build **reproducible Raspberry Pi OS (Lite)** containers for **Bullseye** *and* **Bookworm** in **four flavours** per release:

| Variant | Docker platform | Root‑fs ABI | Runtime speed | Typical use‑case |
| --- | --- | --- | --- | --- |
| **`amd64`** | `linux/amd64` | *aarch64* + static **QEMU** inside | ★☆ (emulated) | Exact Pi parity on any PC |
| **`arm64`** | `linux/arm64`| aarch64 | ★★★★★ native (on Pi 4/5, Graviton, M-Series) | Production containers on 64‑bit Pis |
| **`armv7`** | `linux/arm/v7` | armhf | ★★★ native (Pi 2/3) | Legacy 32‑bit containers |

Each image is **single‑layer**, date‑stamped, and pushed to GHCR.  A `*-latest` tag tracks the newest release for each OS version & variant.

## 📦 Tag layout

```text
# Bullseye examples
bullseye-2024-12-05-amd64   # arm64 rootfs + QEMU (runs on x86)
bullseye-2024-12-05-arm64
bullseye-2024-12-05-armv7
bullseye-latest-amd64
bullseye-latest-*

# Bookworm examples
bookworm-2025-05-15-amd64
bookworm-2025-05-15-arm64
bookworm-2025-05-15-armv7
bookworm-latest-*
```

## 🏗 Build pipeline (high‑level)

1. **Detect newest upstream dates** for Bullseye & Bookworm via `scripts/check_upstream.sh`.
2. **Loop over variants**:
   * `armv7`, `arm64` → download Lite image, mount `loop0p2`, `tar | docker import`.
   * `amd64` → *same* aarch64 root‑fs as above **plus** copy `/usr/bin/qemu-aarch64-static` into the image.  Tag platform as `linux/amd64`.
3. **Attach metadata labels** (`org.opencontainers.image.*`, `variant` if applicable).
4. **Compose one manifest list** containing all three digests.
5. **Push** date tags **and** bump the matching `*-latest` aliases.

All logic lives in:

```text
scripts/
├── build_from_img.sh     # variant+release → image digest
├── build_manifest.sh     # combine digests into OCI manifest list
└── check_upstream.sh     # fetches newest dates per release
```

## 🖥 Local quick‑start

```bash
$ git clone https://github.com/<owner>/<repo>.git && cd <repo>

# Build only native amd64 for Bookworm (zero QEMU needed)
$ sudo ./scripts/build_from_img.sh bookworm amd64 $(date +%F)

# Build all four variants for Bookworm (needs qemu-user-static on x86 hosts)
$ sudo ./scripts/build_manifest.sh bookworm $(date +%F)

# Smoke‑test the QEMU‑layered image on an x86 laptop
$ docker run --rm ghcr.io/<owner>/<repo>:bookworm-latest-amd64-qemu-aarch64 \
    bash -c 'echo arch=$(uname -m); cat /etc/os-release | head -1'
# → arch=aarch64, PRETTY_NAME="Raspbian GNU/Linux 12 (bookworm)"
```

Requirements: Docker 20.10+, `xz`, `util-linux`, and `qemu-user-static` (only if you build/run ARM variants on x86).

## 🤖 GitHub Actions overview

```yaml
# .github/workflows/daily-build.yml
name: Daily multi‑variant build
on:
  schedule:
    - cron: 17 3 * * *
  workflow_dispatch:

jobs:
  matrix-build:
    strategy:
      matrix:
        release: [bookworm, bullseye]
    uses: ./.github/workflows/_release-build.yml
```

The reusable `_release-build.yml` handles **all three variants**:

1. Install binfmt/QEMU.
2. Detect latest date → skip if already tagged.
3. Parallel‑build `arm64`, `armv7`.
4. Build `amd64` (re‑uses the arm64 root‑fs artifact).
5. Combine digests into one manifest list.
6. Push & tag `*-latest-*`.

## 🔄 Advanced Options

* **Force rebuild a variant**: `FORCE_VARIANT=amd64` in workflow dispatch.
* **New architecture**: extend `$VARIANTS` array and add a case in `build_from_img.sh`.
* **Skip 32-bit**: set `SKIP_ARMV7=1` if you only target 64‑bit environments.

## ❓ FAQ

| Question | Answer |
| --- | --- |
| Why build amd64? | CI jobs that execute on x86 sometimes need a Pi‑parity userspace without QEMU overhead. |
| *Does `amd64-qemu-aarch64` hurt CI speed?* | Yes—expect 4‑10× slower. Use it only when you need Pi‑exact behaviour on an x86_64 host. |
| What about ARMv6 (Pi Zero)? | Not included; cross‑compiling an arm/v6 image is slower and rarely needed in container workflows. |
| Can I add packages? | Yes—extend via a standard Dockerfile that targets a release + arch tag. |
| How big are the images? | ARMv7 ≈ 160 MB, arm64 ≈ 180 MB, amd64 ≈ 195 MB compressed. |

## 🪪 License

[MIT](LICENSE) — do what you like; a credit is appreciated.

Made with ❤️, shell scripts, and GitHub Actions so your images stay perfectly in‑sync with Raspberry Pi OS—no matter which CPU you run.

## Author Information

* Joe Clark (@joeofalltrades)
