# Agent Instructions for fugue

fugue is a smeltery project. This file is the canonical guide for any AI coding
agent (Claude, Codex, Gemini, Cursor, Copilot, …) working in this repository. If
you read nothing else, read this and run `make check` before you finish.

fugue runs an AI coding agent in a **no-trace session**: the agent does the work
and leaves nothing behind — no transcript, telemetry, phone-home, credentials,
or caches. The guarantee comes from the *environment*, not from the agent
behaving. Your changes must preserve that.

## Orientation (start here)

1. [`README.md`](README.md) — what fugue is and how it's used.
2. [`docs/README.md`](docs/README.md) — the docs index and reading order.
3. [`docs/architecture.md`](docs/architecture.md) — how a session is assembled
   and torn down, end to end.
4. The source, in this order:
   - [`bin/fugue`](bin/fugue) — host-side launcher (flags, profile, `docker run`).
   - [`src/fugue-entry`](src/fugue-entry) — container entrypoint (firewall,
     scrub, privilege drop).
   - [`profiles/*.env`](profiles) — the per-agent contract.
   - [`Dockerfile`](Dockerfile) — the minimal no-trace image.
5. [`test/`](test) — bats tests for the launcher and the profile contract.
6. [`docs/adr/`](docs/adr) — *why* fugue is built the way it is. Read the
   relevant ADR before changing a load-bearing decision.

## Code map

```text
bin/fugue          host launcher: flags, profile, backend dispatch
bin/lib/fugue-*    backend implementations (docker run / sandbox-exec)
src/fugue-entry    docker entrypoint: nftables allowlist, scrub trap, drop privs
profiles/*.env     per-agent: AGENT_CMD, API_KEY_VARS, API_HOSTS, TELEMETRY_ENV, BACKENDS
Dockerfile         node:22-slim + nftables/su-exec + the 3 image agents, unprivileged user
package.json       pinned agent CLI versions baked into the image (Dependabot-managed)
install.sh         zero-dep curl|bash installer
Formula/fugue.rb   Homebrew formula (canonical copy; release copies it to the tap)
prompts/           LLM prompt templates (e.g. generating a new agent profile)
test/*.bats        launcher arg handling + profile-contract tests (no Docker needed)
scripts/           helper scripts (e.g. mermaid validation)
Makefile           the quality gate — `make check`
docs/              user + contributor docs, ADRs, threat model, reference
```

## Backends

- **docker** (default): full container — tmpfs `$HOME`, nftables egress
  allowlist, telemetry kill-env. Only the 3 image agents (claude/codex/gemini).
- **native** (macOS): the host's agent under `sandbox-exec` — writes leashed to
  the project, secret reads denied. Runs any profile marked `native`; no
  host-level network allowlist. This is how the long tail of agents is supported.

## Security invariants — do not break these

fugue's whole value is the no-trace guarantee. Treat these as hard constraints;
if a task seems to require weakening one, stop and flag it rather than doing it
silently.

- **Ephemerality.** The container stays `--rm` and `$HOME` stays on tmpfs. Never
  add a bind-mount that persists agent state to the host.
- **Fail-closed strict mode.** `--strict` must refuse to run (non-zero exit)
  when it can't install the egress firewall. Never make it fall back to running
  unguarded. See [ADR-002](docs/adr/002-fail-closed-egress-allowlist.md).
- **Minimal egress.** `API_HOSTS` in a profile is an allowlist of holes. Don't
  widen it without a clear reason; never add a wildcard.
- **Credential isolation.** Forward only the one credential named by the agent's
  `API_KEY_VARS`. Never write keys to disk or pass them to a different agent.
- **Least privilege.** Keep `--cap-drop ALL`, `no-new-privileges`, and the drop
  to uid 1001. `NET_ADMIN` is added only for the firewall, only in strict mode.

## Command surface (deterministic)

Everything is a `make` target. Prefer these over ad-hoc commands.

```sh
make check            # the full quality gate — run this before finishing
make fmt              # auto-format shell with shfmt
make check:format     # shfmt -d        (formatting)
make check:lint       # shellcheck       (scripts + profiles)
make check:dockerfile # hadolint         (Dockerfile)
make check:tests      # bats             (test/)
make check:markdown   # markdownlint-cli2 (docs)
make check:mermaid    # render every mermaid diagram (catches syntax errors)
make check:build      # docker build     (image)
make check:site       # npm build        (site)
make check:actions    # actionlint       (workflow YAML)
make check:secrets    # gitleaks         (no committed secrets)
make check:budgets    # file-size and flat-directory budgets
```

Tool binaries are overridable, e.g. `make check:format SHFMT=/path/to/shfmt`.
See [`docs/installation.md`](docs/installation.md#developer-toolchain-optional)
to install the tools, or [`docs/development.md`](docs/development.md) for how
each gate is wired. CI runs the same targets, so green locally means green in CI.

## Conventions and gotchas

- **Shell style is whatever `shfmt -i 2 -ci` produces.** Run `make fmt`; don't
  hand-align. Two-space indent, indented `case` arms.
- **shellcheck must be clean.** `.shellcheckrc` sets `external-sources=true`.
  Scope any disable narrowly and comment why (see the SC2054/SC2034 examples in
  the source).
- **Profiles are sourced shell**, not config. Each carries
  `# shellcheck shell=bash` and a scoped `SC2034` disable. Keep the four-field
  contract; the bats test enforces it.
- **Mermaid in docs is validated.** Inside a `mermaid` block, avoid `;` (read as
  a statement separator) and `<...>` angle brackets (read as arrows) in message
  text — they break the parser. Run `make check:mermaid` after editing diagrams.
- **LOC budgets are enforced.** Keep source/docs/scripts below the configured
  line-count budget and avoid flat directories with too many direct files.
  Update `scripts/*-budgets.json` only for explicit, justified exceptions.
- **The Dockerfile floats versions** in the scaffold and pins at release;
  `.hadolint.yaml` ignores the version-pin rules.
- **Commits** follow Conventional Commits (`feat:`, `fix:`, `docs:`, `ci:`,
  `refactor:`, `test:`, `chore:`). First line ≤ 72 chars, imperative.

## Adding an agent

1. Create `profiles/<name>.env` with `AGENT_CMD`, `API_KEY_VARS`, `API_HOSTS`,
   and `TELEMETRY_ENV` (see [configuration.md](docs/configuration.md)).
2. Add the CLI to `package.json` (pinned) and regenerate the lockfile with
   `npm install --package-lock-only --omit=dev`.
3. `make check:build`, then `make check` — the profile-contract test covers the
   new profile automatically.

## Definition of done

- `make check` is green.
- New behavior has or updates a `test/*.bats` case where practical.
- Docs that describe changed behavior are updated, and any new diagram passes
  `make check:mermaid`.
- No security invariant above is weakened (or it's explicitly called out).
