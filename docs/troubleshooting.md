# Troubleshooting

Common failures, what causes them, and how to fix them. Exit codes are
explained in [usage.md](usage.md#exit-codes).

## Launcher errors (exit 2)

| Message                                            | Cause                                              | Fix                                                              |
| -------------------------------------------------- | -------------------------------------------------- | --------------------------------------------------------------- |
| `no agent given`                                   | You ran `fugue` with no agent name.                | `fugue claude "..."` — see [usage.md](usage.md).                |
| `unknown agent '<x>' ... known: ...`               | No `profiles/<x>.env` exists.                      | Use one of the listed agents, or add a profile ([configuration.md](configuration.md#adding-an-agent)). |
| `unknown flag: <x>`                                | A flag was passed that fugue doesn't recognize, or an agent flag came *before* the agent name. | Put fugue flags before the agent name and agent flags after it. |
| `no API key in env for <agent> (expected one of: ...)` | The credential for that agent isn't exported.   | `export ANTHROPIC_API_KEY=...` (or the listed variable).        |
| `docker not found on PATH`                          | Docker isn't installed or isn't on `PATH`.         | Install Docker and confirm `docker info` works.                 |

## Strict mode refuses to start (exit 3)

```text
fugue-entry: FATAL: nft not present but FUGUE_STRICT=1; refusing to run unguarded
```

`--strict` (the default) needs nftables and the `NET_ADMIN` capability to
install the egress allowlist. This is **fail-closed by design** — fugue won't
run a session it can't firewall. Options:

- Run on a host that grants `NET_ADMIN` to containers (most Linux Docker hosts).
- Drop to env-only mode with `--no-net-isolation` and accept the weaker
  guarantee (see [security.md](security.md)).

## The agent can't reach its API

In `--strict`, only the resolved IPs of the profile's `API_HOSTS` are reachable
on TCP 443. If the API's IP set rotates mid-session, connectivity can drop —
the allowlist is pinned at start.

- Re-run the session (the allowlist re-resolves on start).
- If the agent legitimately needs another host, add it to `API_HOSTS` in the
  profile — but every host added is an egress hole.

## The image is stale or wrong

The launcher defaults to `ghcr.io/smeltery/fugue:latest`. To use a local
build or a specific tag:

```sh
make check:build                          # build :latest locally
fugue --image ghcr.io/smeltery/fugue:<tag> claude "..."
export FUGUE_IMAGE=ghcr.io/smeltery/fugue:<tag>   # or set it globally
```

## CI or the quality gate fails

| Gate            | Likely cause                                        | Fix                                  |
| --------------- | --------------------------------------------------- | ------------------------------------ |
| `check:format`  | Shell source isn't shfmt-clean.                     | `make fmt`.                          |
| `check:lint`    | shellcheck finding.                                 | Fix it, or scope a narrow disable with a comment ([development.md](development.md)). |
| `check:dockerfile` | A new hadolint finding outside the ignored pin rules. | Address it, or extend `.hadolint.yaml` with justification. |
| `check:tests`   | A launcher or profile-contract regression.          | Run `bats test/` locally and read the failing assertion. |
| `check:markdown` | Markdown style drift.                              | Run `make check:markdown` and fix the reported file. |
| `check:mermaid` | A Mermaid diagram does not render.                  | Avoid semicolons and angle brackets in diagram text, then rerun `make check:mermaid`. |
| `check:build`   | The image doesn't build (e.g. a CLI package moved). | Build locally and read the Docker output. |
| `check:actions` | Workflow YAML or runner-label config is invalid.    | Run `make check:actions` and fix the reported workflow line. |
| `check:secrets` | A committed file looks like a secret.               | Remove the secret, rotate it if real, and rerun `make check:secrets`. |
| `check:site`    | The docs site fails type-check or bundle.           | Run `make check:site` and fix the TypeScript or Vite error. |
