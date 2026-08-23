# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 0.x     | Yes       |

Only the latest release on the current major version line receives security
updates.

## Reporting a Vulnerability

**Do not open a public issue for security vulnerabilities.**

Please report vulnerabilities privately through
[GitHub Security Advisories](https://github.com/smeltery/fugue/security/advisories).

1. Go to the [Security Advisories page](https://github.com/smeltery/fugue/security/advisories).
2. Click **"New draft security advisory"**.
3. Describe the vulnerability, including steps to reproduce if possible.

### Response Timeline

- **Acknowledgment**: within 48 hours of your report.
- **Initial assessment**: within 7 days.
- **Fix or mitigation**: within 30 days for confirmed vulnerabilities.

We will keep you informed of progress throughout the process.

## Scope

fugue's guarantee is a *no-trace local session*, with explicit boundaries.
Before reporting, please read the [threat model](../threat-model.md): issues
already documented as out of scope (provider-side logging, a malicious base
image, host-level observation, DNS correlation, mid-session IP rotation) are
known limitations, not vulnerabilities.

In scope, for example: a way to make a `--strict` session reach a host outside
its `API_HOSTS` allowlist; a path by which session state survives container
exit; or credential bleed between agents. When in doubt, report it and we'll
triage.
