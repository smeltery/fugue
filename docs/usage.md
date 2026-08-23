# Usage

```text
fugue [flags] <agent> [agent args...]
fugue shellenv [bash|zsh|fish]
```

`fugue` launches one of the known agents in a sandboxed, no-trace session. Flags
come before the agent name; everything after the agent name is passed through to
the agent unchanged.

## Backends

fugue has two sandbox backends. Pick one with `--backend` (or `FUGUE_BACKEND`).

| Backend            | Isolation                                                                 | Best for |
| ------------------ | ------------------------------------------------------------------------- | -------- |
| `docker` (default) | Full container: tmpfs `$HOME`, nftables egress allowlist (`--strict`), telemetry kill-env, `--rm`. | Strongest guarantee; Linux or Docker Desktop. |
| `native` (macOS)   | No container: the host's agent runs under `sandbox-exec` (Seatbelt) — writes denied outside the project, reads of secrets (SSH keys, cloud creds) denied by the kernel. | Running against your real tree without Docker; the long tail of agents installed on your host. |

The docker backend only runs agents baked into the image (`claude`, `codex`,
`gemini`). The native backend runs **any** agent whose profile lists `native`,
using the copy installed on your host — that's how the other agents are
supported.

## Agents

The agent name must match a profile in [`profiles/`](../profiles); run
`fugue agents` to list profiles with their launch commands and backends.

| Agent      | Command        | Credential(s)                              | Backends        |
| ---------- | -------------- | ------------------------------------------ | --------------- |
| `claude`   | `claude`       | `ANTHROPIC_API_KEY`                        | docker, native  |
| `codex`    | `codex`        | `OPENAI_API_KEY`                           | docker, native  |
| `gemini`   | `gemini`       | `GEMINI_API_KEY` / `GOOGLE_API_KEY`        | docker, native  |
| `opencode` | `opencode`     | `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / … | native          |
| `amp`      | `amp`          | `AMP_API_KEY`                              | native          |
| `copilot`  | `copilot`      | `COPILOT_GITHUB_TOKEN` / `GH_TOKEN` / …    | native          |
| `aider`    | `aider`        | `ANTHROPIC_API_KEY` / `OPENAI_API_KEY`     | native          |
| `goose`    | `goose`        | `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` / … | native          |
| `auggie`   | `auggie`       | `AUGMENT_SESSION_AUTH`                     | native          |
| `pi`       | `pi`           | `ANTHROPIC_API_KEY` / `OPENAI_API_KEY`     | native          |
| `cursor`   | `cursor-agent` | `CURSOR_API_KEY`                          | native          |
| `cline`    | `cline`        | `CLINE_API_KEY` / `ANTHROPIC_API_KEY` / …  | native          |
| `kilo`     | `kilo`         | `KILO_API_KEY` / `ANTHROPIC_API_KEY` / …   | native          |
| `droid`    | `droid`        | `FACTORY_API_KEY`                         | native          |

Native-only agents run the CLI you've installed on your host; install the agent
yourself first. To run one under docker instead, add it to `package.json` and
flip its profile's `BACKENDS` — see [configuration.md](configuration.md).

## Flags

| Flag                      | Default  | Effect                                                                              |
| ------------------------- | -------- | ----------------------------------------------------------------------------------- |
| `--backend <docker\|native>` | `docker` | Execution backend (or `FUGUE_BACKEND`).                                          |
| `--strict`                | on       | docker: hard egress allowlist via nftables. Needs `NET_ADMIN`; **fails closed** if it can't install. |
| `--no-net-isolation`      | off      | docker: env-only mode, no firewall. Telemetry kill-env still applies. Portable, weaker. |
| `--ephemeral-workspace`   | off      | Run against a throwaway copy of the cwd; the host tree is untouched.                 |
| `--workdir <path>`        | cwd      | Use `<path>` as the sandbox workspace.                                               |
| `--add-dir <path>`        | —        | Also expose `<path>` **read-write** inside the sandbox (repeatable).                 |
| `--ro-dir <path>`         | —        | Also expose `<path>` **read-only** inside the sandbox (repeatable).                  |
| `--share-home`            | off      | native: keep the real `$HOME` (for agents that need your host login) instead of an ephemeral one. |
| `--append-profile <path>` | —        | native: append custom Seatbelt rules after fugue's generated rules (repeatable). |
| `--trust-workdir-config`  | off      | native: load `.fugue` from the current directory (`ro-dir`, `add-dir`, `append-profile`). |
| `--env-pass <names>`      | —        | Pass comma-separated host environment variable names into the agent.               |
| `--print-native-profile`  | off      | native: print the generated Seatbelt profile and exit without starting the agent. |
| `--keep-on-error`         | off      | If the agent exits non-zero, skip the scrub (debugging aid).                         |
| `--image <ref>`           | `ghcr.io/smeltery/fugue:latest` | docker: use a specific image.                                  |
| `-h`, `--help`            | —        | Print usage and exit.                                                                |

## Examples

```sh
# default: docker backend, strict egress, working tree mounted read-write
fugue claude "refactor the auth module"

# native backend (macOS): your host's codex under the kernel sandbox
fugue --backend native codex "explain this stack trace"

# pass flags through to the agent after the agent name
fugue codex "explain this stack trace" --model o4-mini

# expose an extra read-only directory (e.g. a shared toolchain cache)
fugue --ro-dir ~/.cache/go-build --backend native aider "..."

# risky migration against a disposable copy of the working tree
fugue --ephemeral-workspace claude "rewrite the build system"

# launch from anywhere, but sandbox a specific project
fugue --workdir ~/src/app --backend native codex "summarize this repo"

# an agent that needs your existing host login (native, real $HOME)
fugue --backend native --share-home auggie "..."

# native backend: add a narrow local Seatbelt rule
fugue --backend native --append-profile ~/.config/fugue/local.sb codex "..."

# native backend: trust this repo's .fugue grants, or inspect the generated policy
fugue --backend native --trust-workdir-config codex "..."
fugue --backend native --print-native-profile claude
```

## Shell wrappers

`fugue shellenv` prints shell functions that route each agent through fugue
automatically. Add it to your shell rc:

```sh
# bash/zsh
eval "$(fugue shellenv)"
# fish
fugue shellenv fish | source
```

Then `claude "..."` runs sandboxed, and `command claude "..."` bypasses fugue and
runs the agent directly.

## Credentials

fugue forwards exactly the credential the agent needs — the first of its
`API_KEY_VARS` that is set in your environment — and nothing else. If none is set
(and, for native, `--share-home` is not used), the launcher exits before starting:

```text
fugue: no API key in env for claude (expected one of: ANTHROPIC_API_KEY)
```

Keys are never written to disk and never shared between agents.

## Exit codes

| Code  | Meaning                                                                 |
| ----- | ---------------------------------------------------------------------- |
| `0`   | The agent ran and exited successfully.                                  |
| `2`   | Launcher usage error (unknown agent/flag/backend, unsupported backend for the agent, missing credential, missing Docker or host CLI). |
| `3`   | docker `--strict` could not install the egress allowlist (e.g. no `nft` / `NET_ADMIN`); fugue refused to run. |
| other | The agent's own exit code, propagated unchanged.                        |

See [troubleshooting.md](troubleshooting.md) for what to do about each.
