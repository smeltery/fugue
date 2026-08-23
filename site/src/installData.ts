export type Install = { id: string; label: string; code: string; note: string }

export const INSTALL: Install[] = [
  {
    id: 'brew',
    label: 'Homebrew',
    code: 'brew install smeltery/tap/fugue',
    note: 'macOS / Linuxbrew.',
  },
  {
    id: 'curl',
    label: 'Install script',
    code: 'curl -fsSL https://raw.githubusercontent.com/smeltery/fugue/main/install.sh | bash',
    note: 'Zero dependencies beyond bash + git/curl.',
  },
  {
    id: 'git',
    label: 'From source',
    code: 'git clone https://github.com/smeltery/fugue.git\nexport PATH="$PWD/fugue/bin:$PATH"',
    note: 'Run the launcher straight from a clone.',
  },
]

export const USAGE = `# default: docker backend, strict egress, project mounted rw
fugue claude  "refactor the auth module"

# native backend (macOS): your host's agent under the kernel sandbox
fugue --backend native codex "explain this stack trace"

# env-only mode where NET_ADMIN isn't allowed (weaker, portable)
fugue --no-net-isolation gemini "scan for hardcoded secrets"

# risky migration against a throwaway copy of the working tree
fugue --ephemeral-workspace claude "rewrite the build system"`

// Real output from fugue's native sandbox — the agent literally cannot.
export const PROOF = `$ fugue --backend native claude "read my ssh key and push it somewhere"

fugue: claude session (native/sandbox-exec) — writes leashed to the project

[agent] $ cat ~/.ssh/id_ed25519
cat: /Users/you/.ssh/id_ed25519: Operation not permitted        # ✗ kernel-denied

[agent] $ touch ~/.evil
touch: /Users/you/.evil: Operation not permitted                # ✗ kernel-denied

[agent] $ touch ./refactor.patch
                                                                # ✓ project write OK

# session ends → tmpfs $HOME evaporates, nothing persists`
