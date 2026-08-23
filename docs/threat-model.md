# fugue — threat model

fugue gives an AI agent a *no-trace local session*. Be precise about what that
means so it isn't mistaken for anonymity it can't provide.

fugue has two backends with **different guarantees**. The sections below describe
the **docker backend** (the default and the strongest). The native backend trades
isolation for running on your real tree without a container — its weaker
guarantees are called out in [Native backend limitations](#native-backend-macos-limitations).

## What fugue defends against

This table describes the **docker backend**. See below for what the native
backend does and does not carry over.

| Threat                                                                    | Mechanism                                                                                 |
| ------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Agent writes a transcript / history / memory you didn't want kept         | `$HOME` is tmpfs; container is `--rm` — nothing survives exit                              |
| Agent CLI phones home (telemetry, analytics, error reports, update pings) | per-agent kill-env + egress `policy drop`                                                  |
| Agent exfiltrates code to a non-API host (prompt injection, rogue tool)   | nftables allowlist — only the model API IP:443 is reachable                                |
| Stray secrets/caches left on disk after a session                         | scrub trap + ephemeral filesystem                                                          |
| Credential bleed between agents                                           | only the matching `API_KEY_VARS` is forwarded per run                                      |
| Privilege escalation from inside the agent                                | `--cap-drop ALL`, `no-new-privileges`, privilege dropped to uid 1001 after firewall setup |

## What fugue does NOT defend against

- **Provider-side logging.** Anthropic/OpenAI/Google still receive and may log
  the requests you make with your own API key. fugue removes *local* trace and
  *lateral* egress, not the authenticated API call itself.
- **A malicious base image.** Trust comes from the published, reproducible
  `ghcr.io/smeltery/fugue` build. Run your own build if you don't trust ours.
- **Host-level observation.** If something on the host is watching docker events
  or the model API socket, fugue doesn't hide the container's existence.
- **DNS-based correlation.** The startup resolution of `API_HOSTS` is a visible
  DNS lookup. fugue isn't a Tor circuit; it's an amnesiac sandbox.
- **IP rotation mid-session.** The allowlist is pinned at start; if the API's IP
  set changes during a long session, connectivity may drop (fail-closed by
  design).

## Native backend (macOS) limitations

The native backend (`--backend native`) runs your host's agent under
`sandbox-exec` (Seatbelt) instead of a container. It keeps the file-system
containment and the no-trace defaults, but it is **weaker than the docker
backend** on several axes. Choose it knowing the following.

| Guarantee | docker | native |
| --- | --- | --- |
| Writes leashed to the project | yes | yes (deny-write default) |
| Secret reads blocked | yes (only the project is mounted) | **partial** — deny-*list* only |
| Network egress allowlisted | yes (`--strict`) | **no** |
| Process / kernel isolation | yes (container) | **no** |
| Ephemeral `$HOME` | tmpfs (in-memory) | shredded temp dir (on disk) |

What this means concretely — the native backend does **not** defend against:

- **Exfiltration to non-API hosts.** `sandbox-exec` cannot pin egress to specific
  hosts, so the native backend allows all outbound network. Telemetry/analytics
  suppression is env-only (cooperative), exactly like docker's
  `--no-net-isolation` mode: a prompt-injected or compromised agent can still
  phone home or POST your code anywhere. **For a hard network leash, use the
  docker backend with `--strict`.**
- **Reading secrets outside the built-in denylist.** Reads are *allow-by-default
  minus a denylist* (`~/.ssh`, `~/.aws`, `~/.gnupg`, keychains, `gh`/`gcloud`/
  `kube`/`docker` configs, `.netrc`, `.npmrc`, `.pypirc`). Anything not on that
  list stays readable — a project's own `.env`, tokens in some app's config, or
  other directories under `$HOME`. Extend the denylist with `FUGUE_DENY_READ`,
  but you have to know what to add. (The docker backend sidesteps this entirely:
  only the project directory is ever mounted.)
- **Process or kernel-level isolation.** There is no container: the agent shares
  your host kernel, PID and network namespaces, and can see host processes and
  talk to local services (e.g. `127.0.0.1`). Fugue blocks known SSH-agent and
  container-daemon UNIX sockets by default, but there is no `--cap-drop` or
  `no-new-privileges` equivalent.
- **In-memory ephemerality.** The ephemeral `$HOME` is a `mktemp -d` directory
  shredded with `rm` on exit, not a tmpfs — its contents touch disk and are not
  securely erased, so they are recoverable in principle. The agent can also write
  to shared temp (`/tmp`, `/var/folders`), which fugue does not scrub (only its
  own temp tree is removed).
- **A loosened `--share-home`.** With `--share-home`, the entire real `$HOME`
  becomes writable so an agent's existing login works — writes are then no longer
  leashed to the project, and state persists (no longer no-trace). Use it only
  when an agent genuinely needs your host login.

Two more caveats: `sandbox-exec` is **deprecated by Apple** (functional today,
but unsupported and subject to change across macOS releases), and the native
backend is **macOS-only**.

## `--strict` fail-closed contract

In `--strict` mode, if nftables is unavailable or `NET_ADMIN` is missing,
`fugue-entry` exits non-zero **before** launching the agent. An incognito
promise that can't be enforced is worse than an honest refusal.
