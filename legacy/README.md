# `legacy/` — what the clone brought with it. None of it is live.

**E's call, 2026-09-06.** This project was **cloned from an earlier build** that was developed with
a two-tool workflow — architecture designed in Claude Cowork, handed to Claude Code to build. This
repo is Claude Code only. The clone copied the parent's whole working tree, and the parts that had
nothing to do with a native iOS app were never removed, so an iOS repo carried a half-built web app
at its root for three weeks.

Nothing in here is built, run, deployed or imported. It is kept because it is **referenced**, not
because it works.

| what | why it is kept |
|---|---|
| `src/` | The React prototype the SwiftUI app was ported FROM, 25 files. CLAUDE.md still cites it as the source of the palette and layouts, so the port can be checked against it. Last touched 2026-08-18. |
| `index.html`, `package.json`, `bun.lock`, `server.ts`, `vite.config.ts`, `tsconfig.json`, `metadata.json`, `.env.example` | The prototype's build tooling. It ran the web app, never the iOS one. |

## What is NOT here, and why

**`aws-backend/` was deleted, not archived.** The AWS layer was torn down on 2026-08-21, it has an
archive outside this repo at `~/Documents/LifeOS-AWS-Archive-2026-08-21`, and it is in this repo's
git history. A third copy nobody has opened since the teardown is not a record, it is clutter.

## The one thing to be sure of

**The live Firebase functions do not depend on any of this.** `functions/` carries its own
`package.json`, and `firebase.json` deploys it from `functions` directly — checked before this
folder was created, precisely so moving the root tooling could not break a deploy.
