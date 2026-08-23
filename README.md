<img src="site/public/favicon.svg" alt="fugue logo" width="72" height="72" />

# fugue

[![CI](https://github.com/smeltery/fugue/actions/workflows/ci.yml/badge.svg)](https://github.com/smeltery/fugue/actions/workflows/ci.yml)
[![security](https://github.com/smeltery/fugue/actions/workflows/security.yml/badge.svg)](https://github.com/smeltery/fugue/actions/workflows/security.yml)
[![Release](https://img.shields.io/github/v/release/smeltery/fugue?logo=github&color=blue)](https://github.com/smeltery/fugue/releases)
[![License](https://img.shields.io/badge/License-PolyForm_Shield_1.0-blue)](LICENSE)

> Incognito mode for AI coding agents — Claude, Codex, Gemini, and a dozen more.

A *fugue state* is dissociative amnesia: you act, then keep no memory of having
acted. `fugue` does that to an AI agent. The agent runs, does the work, and
leaves **nothing behind** — no transcript, no telemetry, no phone-home, no
lingering credentials or caches.

The guarantee does not rely on the agent behaving. The **environment is made
incapable of persisting anything**:

| Trace surface | Normally | Under fugue |
| --- | --- | --- |
| Session state / history | `~/.claude`, `~/.codex`, `~/.gemini` persist | `$HOME` on **tmpfs**, gone on exit |
| Telemetry / analytics / error reports | enabled by default | killed per-agent via env |
| Autoupdate checks | phone home on launch | disabled |
| Network egress | unrestricted | **nftables allowlist** → model API only |
| Workspace artifacts / caches | linger on disk | container is `--rm`; optional tmpfs workspace |

If the agent *tries* to write a transcript or hit an analytics endpoint under
`--strict`, it physically can't — the firewall drops it and the filesystem
evaporates.

## Install

```sh
brew install smeltery/tap/fugue
# or, zero-dependency:
curl -fsSL https://raw.githubusercontent.com/smeltery/fugue/main/install.sh | bash
```

## Usage

```sh
fugue claude  "refactor the auth module"
fugue codex   "explain this stack trace"
fugue gemini  "scan this repo for hardcoded secrets"

# env-only mode (no firewall; portable, weaker guarantee)
fugue --no-net-isolation claude "..."

# don't even touch the host working tree — edit a throwaway copy
fugue --ephemeral-workspace gemini "try a risky migration"

# run automatically: claude/codex/... route through fugue (command claude bypasses)
eval "$(fugue shellenv)"
```

Credentials are read from your host env and forwarded **only** to the matching
agent — never written to disk, never shared across agents.

## Two backends

| Backend | Isolation | Notes |
| --- | --- | --- |
| **docker** (default) | container: tmpfs `$HOME`, nftables egress allowlist, telemetry kill-env, `--rm` | strongest guarantee; the 3 image agents |
| **native** (macOS) | host agent under `sandbox-exec` (Seatbelt): writes leashed to the project, secret reads (SSH keys, cloud creds) kernel-denied | no Docker; runs any of the 14 agents you've installed |

```sh
fugue --backend native codex "explain this stack trace"
```

fugue supports **14 agents** — claude, codex, gemini, opencode, amp, copilot,
aider, goose, auggie, pi, cursor, cline, kilo, droid — via per-agent profiles.
The docker image stays minimal (the first three); the rest run through the native
backend. See [docs/usage.md](docs/usage.md).

## How it works

In the default **docker backend**, `bin/fugue` assembles a hardened `docker run`
(the native backend is described in [docs/architecture.md](docs/architecture.md)):

- `--tmpfs /home/agent` — ephemeral `$HOME`; all agent state lands here and dies on exit
- `--cap-drop ALL` + `--security-opt no-new-privileges` — minimal privilege
- `--cap-add NET_ADMIN` (strict only) — just enough for the entrypoint to install the egress allowlist, then privileges are dropped to the `agent` user
- per-agent telemetry kill-env from `profiles/<agent>.env`
- `--rm` — the container and everything in it is destroyed when the agent exits

Inside, `src/fugue-entry` resolves the profile's `API_HOSTS`, pins their IPs into
an nftables `policy drop` allowlist (DNS + loopback + established only), wires a
scrub trap, drops privileges, and execs the agent.

In `--strict` mode fugue **fails closed**: if it can't install the firewall, it
refuses to run rather than silently leak.

## Adding an agent

Drop a `profiles/<name>.env` defining `AGENT_CMD`, `API_KEY_VARS`, `API_HOSTS`,
`TELEMETRY_ENV`, and `BACKENDS`. Use `BACKENDS="native"` to run the agent's CLI
from your host under the sandbox; to also bake it into the docker image, add the
CLI to `package.json` and set `BACKENDS="docker native"`. See
[docs/configuration.md](docs/configuration.md#adding-an-agent).

## Limitations

- The allowlist pins IPs at session start; agents using a host that rotates IPs
  mid-session may lose connectivity (re-run, or widen the profile).
- `--strict` needs `NET_ADMIN`; on hosts that forbid it, use `--no-net-isolation`
  (telemetry env still applies, but there's no hard network leash).
- fugue hides the *session*, not the API call itself — Anthropic/OpenAI/Google
  still see the requests you authenticate. It removes local trace and lateral
  egress, not provider-side logging.

See [docs/threat-model.md](docs/threat-model.md) for what fugue does and does not
defend against.

## Documentation

Full docs live in [`docs/`](docs/):

- [Quickstart](docs/quickstart.md) — first no-trace session in minutes.
- [Usage](docs/usage.md) — every flag, agent, and exit code.
- [Configuration](docs/configuration.md) — the profile contract and `FUGUE_*` env.
- [Architecture](docs/architecture.md) — how a session is built and torn down.
- [Security](docs/security.md) and the [threat model](docs/threat-model.md).
- [Development](docs/development.md) — the quality gate and contributor workflow.
- [Architecture decisions](docs/adr/) — why fugue is built the way it is.

## Contributing

Run `make check` before opening a PR; it runs the same gate CI does (shfmt,
shellcheck, hadolint, bats, markdownlint, mermaid, and the image build).
Install the matching pre-commit hooks with `pre-commit install`. See
[docs/reference/CONTRIBUTING.md](docs/reference/CONTRIBUTING.md).

AI coding agents working in this repo should start at [AGENTS.md](AGENTS.md) —
the canonical agent guide (command surface, code map, and the security
invariants that must not be weakened).

## License

[PolyForm Shield 1.0.0](LICENSE). Published at `ghcr.io/smeltery/fugue`.
