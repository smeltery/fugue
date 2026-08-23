# Quickstart

Get from a clean checkout to a no-trace agent session in a few minutes.

## 1. Prerequisites

- **Docker** with the daemon running (`docker info` should succeed).
- An **API key** for at least one agent, exported in your shell:
  - Claude: `ANTHROPIC_API_KEY`
  - Codex: `OPENAI_API_KEY`
  - Gemini: `GEMINI_API_KEY` or `GOOGLE_API_KEY`
- For the strongest guarantee (`--strict`, the default), a host that lets the
  container hold `NET_ADMIN`. Most Linux Docker hosts do. See
  [troubleshooting.md](troubleshooting.md) if strict mode refuses to start.

## 2. Get fugue

```sh
git clone https://github.com/smeltery/fugue.git
cd fugue
```

`bin/fugue` is the launcher; run it directly or put it on your `PATH`:

```sh
export PATH="$PWD/bin:$PATH"
```

## 3. Build (or pull) the image

Build the image locally:

```sh
make check:build          # builds ghcr.io/smeltery/fugue:latest
```

Or pull the published image (the launcher uses it by default):

```sh
docker pull ghcr.io/smeltery/fugue:latest
```

## 4. Run a session

```sh
export ANTHROPIC_API_KEY=sk-...

fugue claude "refactor the auth module"
```

fugue mounts your current directory at `/workspace`, forwards only the one
credential the agent needs, and runs the agent under a tmpfs `$HOME` behind an
egress allowlist. When the agent exits, the container is removed and nothing it
wrote — history, telemetry, caches — survives.

Try the other agents and modes:

```sh
fugue codex  "explain this stack trace"
fugue gemini "scan this repo for hardcoded secrets"

# env-only mode (no firewall; portable, weaker guarantee)
fugue --no-net-isolation claude "..."

# don't touch the host working tree — edit a throwaway copy
fugue --ephemeral-workspace gemini "try a risky migration"
```

## 5. Next steps

- [usage.md](usage.md) — every flag and what it changes.
- [architecture.md](architecture.md) — what actually happens under the hood.
- [development.md](development.md) — run the quality gate before you change
  anything.
