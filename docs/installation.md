# Installation

fugue is a Bash launcher (`bin/fugue`) plus a container image. There is nothing
to compile; you need Docker to run sessions, and a handful of shell tools only
if you intend to run the quality gate.

## Runtime requirements

Requirements depend on the backend (see [usage.md](usage.md#backends)):

| Requirement | Why                                                      |
| ----------- | -------------------------------------------------------- |
| Bash 4+     | the launcher uses arrays and `${!var}` indirection      |
| Docker      | **docker backend** — every session is a `docker run --rm` container |
| `NET_ADMIN` capability | docker `--strict` (the default) — the entrypoint installs an nftables egress allowlist |
| macOS + `sandbox-exec` | **native backend** — kernel sandboxing (built into macOS) |
| the agent's CLI installed on the host | native backend runs your host's copy of the agent |

docker `--strict` needs the container to hold `NET_ADMIN`. On hosts that forbid
it, run with `--no-net-isolation` (telemetry env still applies, but there is no
hard network leash), or use the native backend. See [security.md](security.md).

## Install the launcher

### Homebrew

```sh
brew install smeltery/tap/fugue
```

### Install script (zero-dependency)

```sh
curl -fsSL https://raw.githubusercontent.com/smeltery/fugue/main/install.sh | bash
```

It installs the tree under `~/.local/share/fugue` and links `fugue` into
`~/.local/bin` (override with `FUGUE_PREFIX`). Make sure that bin dir is on your
`PATH`.

### From a clone

```sh
git clone https://github.com/smeltery/fugue.git
cd fugue
export PATH="$PWD/bin:$PATH"   # add to your shell profile to persist
```

To route agents through fugue automatically, add the shell wrappers:

```sh
eval "$(fugue shellenv)"        # bash/zsh; fish: fugue shellenv fish | source
```

## Get the image

The launcher defaults to `ghcr.io/smeltery/fugue:latest`. Either pull it:

```sh
docker pull ghcr.io/smeltery/fugue:latest
```

…or build it from source:

```sh
make check:build
```

Override the image per run with `--image <ref>` or globally with the
`FUGUE_IMAGE` environment variable. See [configuration.md](configuration.md).

## Credentials

fugue reads API keys from your host environment and forwards **only** the one
the chosen agent needs:

```sh
export ANTHROPIC_API_KEY=sk-...   # claude
export OPENAI_API_KEY=sk-...      # codex
export GEMINI_API_KEY=...         # gemini (GOOGLE_API_KEY also accepted)
```

Keys are passed to the container as environment variables for that single run;
they are never written to disk and never shared across agents.

## Developer toolchain (optional)

The easiest path is the checked-in Flox environment:

```sh
flox activate -- make check
```

`make check:mermaid` uses Puppeteer's browser cache. If Mermaid reports a
missing `chrome-headless-shell`, install it once from inside Flox:

```sh
flox activate -- bash -lc 'npx puppeteer browsers install chrome-headless-shell@131.0.6778.85'
```

The quality gate (`make check`) uses these tools. Install only what you plan to
run locally — CI installs them itself.

| Tool                                                | Purpose                          | macOS (Homebrew)        |
| --------------------------------------------------- | -------------------------------- | ----------------------- |
| [shellcheck](https://www.shellcheck.net/)           | shell linting                    | `brew install shellcheck` |
| [shfmt](https://github.com/mvdan/sh)                | shell formatting                 | `brew install shfmt`    |
| [hadolint](https://github.com/hadolint/hadolint)    | Dockerfile linting               | `brew install hadolint` |
| [bats](https://github.com/bats-core/bats-core)      | shell test runner                | `brew install bats-core` |
| [Node.js / npm](https://nodejs.org/)                 | site build and docs tooling      | `brew install node`     |
| [markdownlint-cli2](https://github.com/DavidAnson/markdownlint-cli2) | Markdown linting | `npm install -g markdownlint-cli2` |
| [mermaid-cli](https://github.com/mermaid-js/mermaid-cli) | Mermaid diagram validation    | `npm install -g @mermaid-js/mermaid-cli` |
| [actionlint](https://github.com/rhysd/actionlint)   | workflow YAML linting            | `brew install actionlint` |
| [gitleaks](https://github.com/gitleaks/gitleaks)    | secret scanning                  | `brew install gitleaks` |

See [development.md](development.md) for how each plugs into the gate.
