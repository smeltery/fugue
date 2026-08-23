<img src="public/favicon.svg" alt="fugue logo" width="72" height="72" />

# fugue site

The marketing site for [fugue](https://github.com/smeltery/fugue) — a single-page
Vite + React + TypeScript app, terminal/dark theme, no runtime dependencies
beyond React.

## Develop

```sh
cd site
npm install
npm run dev        # http://localhost:5173
```

## Build

```sh
npm run build      # type-checks (tsc) then bundles to dist/
npm run preview    # serve the production build locally
```

## Deploy to Vercel

This app lives in the `site/` subdirectory of the fugue repo, so point Vercel at
that directory:

1. In Vercel, **New Project** → import `smeltery/fugue`.
2. Set **Root Directory** to `site`.
3. Framework preset auto-detects **Vite** (build `npm run build`, output `dist`).
4. Deploy.

Or from the CLI:

```sh
cd site
npx vercel            # first run links/creates the project
npx vercel --prod     # promote to production
```

### Custom domain

Add the domain in the Vercel project's **Domains** settings and point its DNS at
Vercel (an `A`/`CNAME` record per Vercel's instructions). No code change needed.

## Editing content

All copy lives in [`src/data.ts`](src/data.ts) — agents, the trace-surface
table, backends, grants, install snippets, and the proof terminal. Layout is in
[`src/App.tsx`](src/App.tsx); the theme is [`src/index.css`](src/index.css).
