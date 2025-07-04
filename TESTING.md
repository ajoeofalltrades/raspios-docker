# Testing & Quality‑Assurance Guide

This document describes **how we lint, test, and verify** the Raspberry Pi OS Docker build project—locally and in CI. Follow it when contributing code or debugging the pipeline.

## 📚 Test Pyramid

| Layer  | Tooling | What it checks | Trigger |
| --- | --- | --- | --- |
| **Static analysis** | *pre‑commit* hooks (ShellCheck, shfmt, actionlint, markdownlint, checkmake) | Syntax, style, obvious logic errors | Every `git commit`, **`make lint`**, and CI **lint** job |
| **Unit tests** | *Bats‑core* in `tests/unit/` | Script functions in isolation (e.g., date parsing in `check_upstream.sh`) | `make unit` and CI **unit** job                          |
| **Integration / smoke** | Bats in `tests/integration/` | Asserts each built image boots and reports expected arch / OS codename | `make smoke` and CI **build‑and‑smoke** job              |
| **Extended monthly** | Dockle, Trivy, systemd tests | CVE scan, systemd boot, package‑install sanity | Saturday 03:00 UTC via separate workflow |

## 🔄 Local developer workflow

```bash
# 0. one‑time setup
python3 -m venv .venv && source .venv/bin/activate
pip install --upgrade pip pre-commit
pre-commit install --install-hooks

# 1. hack some code …

# 2. run fast checks before commit (same as CI lint job)
make lint

# 3. run unit tests
make unit

# 4. (optional) build images + smoke‑test
make smoke RELEASE=bookworm DATE=$(date +%F)
```

All commands are wrappers around targets in the **Makefile** (see below).

## 🛠 Makefile targets

| Target | Description |
| --- | --- |
| `make pre-commit` | Runs all linters—ShellCheck, shfmt, actionlint, markdownlint, checkmake.               |
| `make unit` | Executes Bats unit tests in `tests/unit/`. |
| `make smoke` | Builds requested images (default: bookworm, today’s date) then runs integration tests. |
| `make clean` | Deletes `.venv`, `dist/`, `tmp/` build artefacts.                                      |
| `make help` | Lists available targets with short descriptions. |

**Phony declaration** (excerpt from `Makefile`):

```makefile
.PHONY: help pre-commit lint all test clean
```

## 🐶 Pre‑commit configuration (`.pre-commit-config.yaml`)

Key sections:

Running `pre-commit run --all-files` executes the same lint suite CI uses.

## 📝 Markdown lint rules (`.markdownlintrc`)

```json
{
  "default": true,
  "MD013": false
}
```

This file must be named **`.markdownlintrc`** and in **JSON format** so both the CLI and the ReviewDog action auto‑detect it.

## 🤖 Continuous‑Integration jobs

| Job | Runner | Key steps |
| --- | --- | --- |
| **lint** | `ubuntu-latest` | Checkout → run pre‑commit (same as `make lint`) with ReviewDog annotations |
| **unit** | `ubuntu-latest` | Checkout → run `make unit` |
| **build‑and‑smoke** | `ubuntu-latest` (with QEMU) | Build images for PR sha → run `make smoke`|
| **nightly build** | `ubuntu-latest` (03:17 UTC)     | Detect new upstream → build & push images + run smoke tests |
| **weekly‑extended** | `ubuntu-latest` (Sat 03:00 UTC) | Pull `*-latest-*` images → run Trivy CVE scan, Dockle checks, systemd boot |

Artifacts: image tarballs and test logs are uploaded for 7 days for debugging.

## 🐚 Unit‑test example (Bats)

```bash
@test "check_upstream parses latest date" {
  load 'test_helper/bats-support/load'
  run scripts/check_upstream.sh < test/fixtures/bookworm-index.html
  assert_output "2025-05-15"
}
```

Fixtures live in `tests/fixtures/` so tests run offline.

## 🧪 Integration smoke‑test outline

```bash
@test "uname matches variant" {
  run docker run --rm $IMAGE uname -m
  [[ "$variant" == "amd64" ]] && assert_output "aarch64" || assert_output "$variant"
}
```

Matrix variables `IMAGE` and `variant` are supplied by the CI workflow.

## 🕰 Monthly extended tests (planned)

1. **CVE scan** – Trivy `--severity HIGH,CRITICAL` on each latest tag.
2. **Systemd boot** – Run container privileged, expect `systemctl is-system-running --wait` → `running` in <30 s.
3. **Package install** – `apt-get install -y git build-essential` succeeds.

Failures open a GitHub issue via the **create‑issue‑from‑workflow** action.

### Troubleshooting checklist

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Pre‑commit hook fails to install shfmt | Old mirror URL | Ensure repo is `scop/pre-commit-shfmt` |
| `make smoke` hangs on x86 | Missing `binfmt_misc` entries | Run `docker run --privileged --rm tonistiigi/binfmt --install all` |
| Markdown line‑length errors in CI | Wrong config filename | File must be `.markdownlint-cli2.yaml` |

Happy testing! Keep the pipeline green by running **`make pre-commit`** before every push.

## Author Information

- Joe Clark (@ajoeofalltrades)
