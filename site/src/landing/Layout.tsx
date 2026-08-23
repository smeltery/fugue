import { GhostMark } from '../GhostMark'
import { REPO } from '../data'

export function Nav() {
  return (
    <header className="nav">
      <div className="container nav-inner">
        <a className="brand" href="#top">
          <span className="brand-mark" aria-hidden="true">
            <GhostMark />
          </span>
          fugue
        </a>
        <nav className="nav-links">
          <a href="#how">How it works</a>
          <a href="#backends">Backends</a>
          <a href="#agents">Agents</a>
          <a href="#policy-builder">Builder</a>
          <a href="/docs">Docs ↗</a>
          <a className="nav-cta" href={REPO} target="_blank" rel="noreferrer">
            GitHub ↗
          </a>
        </nav>
      </div>
    </header>
  )
}

export function Footer() {
  return (
    <footer className="footer">
      <div className="container footer-inner">
        <div>
          <a className="brand" href="#top">
            <span className="brand-mark" aria-hidden="true">
              <GhostMark />
            </span>
            fugue
          </a>
          <p className="muted">
            Published at <code>ghcr.io/smeltery/fugue</code> ·{' '}
            <a href={`${REPO}/blob/main/LICENSE`} target="_blank" rel="noreferrer">
              PolyForm Shield 1.0.0
            </a>
          </p>
        </div>
        <div className="footer-links">
          <a href={REPO} target="_blank" rel="noreferrer">
            GitHub
          </a>
          <a href="/docs">Docs</a>
          <a href={`${REPO}/blob/main/docs/threat-model.md`} target="_blank" rel="noreferrer">
            Threat model
          </a>
          <a href="https://smeltery.dev" target="_blank" rel="noreferrer">
            smeltery
          </a>
        </div>
      </div>
    </footer>
  )
}
