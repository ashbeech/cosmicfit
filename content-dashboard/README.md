# Content Dashboard

Web GUI for Ash and Maria to review, search, and reword the Cosmic Fit app's
user-facing copy — with per-paragraph versioning, word-level diffs, and a
byte-faithful export back to the repo's JSON.

**Full spec / source of truth:** [`../docs/handoff/content_dashboard_plan.md`](../docs/handoff/content_dashboard_plan.md).
This README only covers running it locally.

- **Stack:** Next.js 14 (App Router) + TypeScript, `@supabase/supabase-js`
  (service-role, server-only), `jose` auth, argon2 password hashing, `jsdiff`,
  `@leeoniya/ufuzzy` (client-side ranked search).
- **Source of truth for content:** Supabase (`dash_*` tables). Repo JSON is an
  *export artifact*, never hand-edited.
- **This phase is local-only.** Vercel deployment is a later, owner-run step.

---

## Prerequisites

- Node 18+ and npm.
- Access to the existing **hosted** Supabase project (URL + service-role key).
- The migration applied and the Storage bucket created (steps 1–2 below).

---

## First-run setup (do these in order)

The seed script fails loudly if the schema or bucket is missing, so don't skip
1–2.

### 1. Apply the migration
Open the Supabase dashboard → **SQL Editor** → paste the full contents of
[`supabase/migrations/012_content_dashboard.sql`](supabase/migrations/012_content_dashboard.sql)
and run it. This creates the `dash_*` tables with RLS enabled and no policies
(deny-all to the public API; only the server's service-role key can read/write).

### 2. Create the Storage bucket
Supabase dashboard → **Storage** → **New bucket** → name **`dash-baselines`**,
**Private** (not public). This holds the ~10.6 MB blueprint baseline blob.

### 3. Configure env
```bash
cp .env.local.example .env.local
```
Fill in every value. `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` come from
Supabase → Project Settings → API (the service-role key is the same secret the
repo's Python tooling calls `SUPABASE_SECRET_KEY`). Generate `SESSION_SECRET`
with `openssl rand -base64 32`. Set the two `SEED_*` passwords. **Never commit
`.env.local`.**

### 4. Install
```bash
npm install
```

### 5. Seed baselines + field registry
```bash
npm run seed
```
Imports the three content files into `dash_baseline` (blob → Storage) and builds
the editable-field registry in `dash_field`.

> ⚠️ **Seed source-of-truth.** The seed reads **today's committed V2**
> `data/style_guide/blueprint_narrative_cache.json` (with the capitalization +
> hygiene fixes) — never a `_pre_sg4`/older cache. The script asserts the
> seeded baseline's sha256 matches the current committed file and **aborts on
> mismatch**. If it aborts, you're pointed at the wrong file — fix that before
> continuing, or edits will silently regress on the next export.

### 6. Seed users
```bash
npm run seed:users
```
Inserts `maria` and `ash` with argon2 hashes from the `SEED_*` env passwords.
Hand the passwords to each person out-of-band.

### 7. Run
```bash
npm run dev
```
Open http://localhost:3000 and log in.

---

## What you should be able to do locally

- Log in as `maria` / `ash`; every page and `/api/*` is gated (unauthenticated → login).
- Browse blueprint clusters, filtered by **Venus / Moon / Element** facets.
- **Search** any word — client-side, ranked, typo-tolerant, instant (≥2 chars).
- Edit a paragraph in an always-on textarea; **Save** per box (bottom-right).
- Expand a field's **history dropdown**: prior versions with word-diff, author,
  timestamp; **Restore** any prior version (a forward write — nothing is lost).
- View the global **`/changes`** feed across all fields.
- **Export** a bundle (3 content files + `manifest.json`) and download it.

---

## Export → repo hand-off (owner: Ash)

Export produces a **downloadable bundle only** — the app never writes into the
repo. To ship copy into an iOS build:

1. Export in the dashboard → download the bundle.
2. **Backup gate first:**
   `python3 tools/backup_content_sources.py backup --domain all --label export-vNN`
3. Drop files at canonical paths:
   - `data/style_guide/blueprint_narrative_cache.json` **and**
     `data/style_guide/blueprint_narrative_cache_sg4.json` (identical bytes — keeps
     the `inspector/` consumer in sync)
   - `data/style_guide/astrological_style_dataset.json`
   - `Cosmic Fit/Resources/TarotCards.json` (real file, overwrite in place)
4. `git diff` should show only the fields you changed.
5. Build in Xcode; confirm the log reads `Loaded 576 archetype clusters (schema v2)`.
6. Commit the files + `manifest.json`.

The **core safety test**: a zero-override export must be **byte-identical**
(sha256) to the committed baseline. This runs as an automated check — see the
plan's Verification section.

---

## Scripts

| Command | Does |
|---|---|
| `npm run dev` | Start the local dev server (http://localhost:3000). |
| `npm run seed` | Import baselines + build the field registry (sha256-gated). |
| `npm run seed:users` | Insert `maria` + `ash` from `SEED_*` env passwords. |
| `npm run build` | Production build (used by Vercel later). |
| `npm test` | Round-trip / export integrity checks. |

---

## Not in this phase

- Vercel deployment (owner-run: root dir = `content-dashboard`, env vars, ignored
  build step).
- Retiring `tools/review_tool.py` (owner-run, after this is verified).
- Live multi-editor presence (the optimistic `version` 409 guard is the v1 safety net).
