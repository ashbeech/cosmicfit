# Content Dashboard — Plan

## Context

Ash (technical owner) and Maria (non-technical fashion partner) need a GUI to reword the app's copy. Today, all user-facing prose lives in JSON files in the repo (`data/style_guide/blueprint_narrative_cache.json` etc.), which the iOS app bundles via symlinks in `Cosmic Fit/Resources/` — so editing a JSON + rebuilding is all it takes to ship new wording. The only current tool is `tools/review_tool.py` (Flask, local, **read-only** on copy). Maria needs to actually edit, from anywhere, safely.

**Goal:** a Vercel-hosted web dashboard where either user logs in, searches for a word, edits any paragraph inline (no edit button — always-on textareas with a per-field Save), and every change is versioned with a who/what/when diff view. Because Vercel functions **cannot write back into the repo** (read-only filesystem), edited content lives in **Supabase** (the existing project — same instance, new `dash_`-prefixed tables), and an **Export** feature reconstructs the JSON files for Ash to drop into the next iOS build. This matches the stated future direction (server-hosted content) and makes a later "app fetches content from the server" step a natural extension.

### ⚠️ Seed source-of-truth (must-read before seeding)
SG-4 work is being promoted to **V2** (with V1 retained only for rollback). The editor tool **MUST be seeded from the current normalized V2 `data/style_guide/blueprint_narrative_cache.json` as it stands today** — the version that already includes the capitalization fix and hygiene work — **not** an older cache (e.g. the `_pre_sg4` / v1 backup). If it seeds from a stale cache, that fix and any hygiene work will **silently regress on the next Export** (the exporter reproduces whatever baseline it was seeded from). **Action:** tell the other dev explicitly that the live tool's source-of-truth = today's V2 file. The reseed/reconcile policy (below) exists precisely to keep this true whenever the file is regenerated.

### Confirmed decisions
- **Source of truth:** Supabase (existing instance, new tables). Repo JSON becomes an *export artifact*, not hand-edited.
- **Editable content:** all three user-facing copy files, **prose fields only** (no add/remove of structured list items).
- **Edit UX:** always-editable textareas, one per section field, each with its own Save button.
- **Auth:** two users (`maria`, `ash`), username + simple password, no email — but treated as a *real* gate since the URL is public.
- **Location:** new top-level `content-dashboard/` (peer of `inspector/`, `web/`, `tools/`, `supabase/`), deployed to Vercel from the existing GitHub remote.

### v1 editable-field scope per file (decide now, not a follow-up)
The requirement→map below is blueprint-shaped (16 sections, Venus/Moon/Element facets). The other two files need their **own** enumerators + grouping, or Maria can't edit them in v1. Concrete v1 scope:
- **`blueprint_narrative_cache.json`** — all 16 prose sections per cluster (as today). Facets: Venus / Moon / Element. **In scope, full.**
- **`TarotCards.json`** — editable = each card's **prose fields only** (e.g. `meaning` / description / interpretation strings; enumerate the exact keys in `lib/content/schema.ts`). **Structured/list fields (keywords, arrays) are read-only in v1** (matches the "prose only, no add/remove of list items" decision). Grouping/nav = one group per card (by card name); no facets needed. **In scope.**
- **`astrological_style_dataset.json`** — the prose arrays (`code_leaninto`, `lean_into_bias`, …) are the ambiguous ones. **v1 decision: expose them as whole-array block-edit textareas** (one editable block per array, `\n`-joined, split back on save; still "prose only, item count preserved"), grouped by sign/section. If review shows this is too noisy, **defer this file to v2** — but the blueprint + tarot files ship regardless. Mark the choice before seeding so the enumerator is built to match.

---

## Architecture

**Stack:** Next.js 14 (App Router) + TypeScript, `@supabase/supabase-js` (service-role key, server-only), `jose` (signed httpOnly session cookie, edge-middleware compatible), `@node-rs/argon2` or `bcryptjs` (password hashing), `jsdiff` (word-level diffs), **`@leeoniya/ufuzzy`** (client-side ranked fuzzy search; Fuse.js is the fallback choice). Styling ports the `tools/review_tool.py` palette/layout so Maria sees a familiar UI. No component library.

**Data flow:** Editor UI ⇄ Supabase (`dash_*` tables) → **Export** endpoint reconstructs `blueprint_narrative_cache.json`, `TarotCards.json`, `astrological_style_dataset.json` + a `manifest.json` → Ash commits them → next Xcode build bundles them.

**Field addressing (no IDs in the data):** every editable field is identified by an RFC-6901 **JSON pointer** + a human-readable **natural key**. Export = deep-clone the frozen baseline tree → `setByPointer(pointer, value)` for each override → serialize with that file's exact formatting profile.

### Directory layout — `content-dashboard/`
```
middleware.ts                 # jose auth gate for all pages + /api
app/
  login/page.tsx
  (protected)/
    layout.tsx                # session check + nav
    page.tsx                  # file/cluster picker
    editor/[file]/[groupKey]/page.tsx   # server-fetch fields for one cluster/card/sign
    changes/page.tsx          # diff feed (version history)
  api/
    auth/{login,logout,session}/route.ts
    content/route.ts          # GET ?file=&group=&q=  (list + search)
    content/field/route.ts    # PATCH one field (Server Action preferred)
    changes/route.ts          # GET edit-log feed
    export/route.ts           # POST -> reconstruct file(s) + manifest, download
lib/
  supabase/server.ts          # service-role client (import 'server-only')
  auth/{session,password}.ts
  content/{paths,schema,lint,export}.ts   # pointer build/parse, field enumerators, ported validation, reconstruction
components/
  EditableField.tsx  FieldHistory.tsx  SearchBar.tsx  SignFilter.tsx  LintWarnings.tsx  WordDiff.tsx  ClusterNav.tsx
scripts/
  seed.ts        # import 3 JSON files -> baselines + field registry
  seed-users.ts  # insert maria + ash (argon2 hashes, passwords via env, never committed)
supabase/migrations/012_content_dashboard.sql
```

### Supabase data model (`public` schema, `dash_` prefix, **RLS enabled + no policies = deny-all via PostgREST**; only service-role server code touches them)
- **`dash_users`** — `id, username UNIQUE, password_hash (argon2id), display_name`.
- **`dash_baseline`** — one row per imported file version: `version_id, repo_path, storage_path, sha256, byte_size, tree jsonb, imported_at`. Store the 10.6 MB blueprint blob in **Supabase Storage** (bucket `dash-baselines`), not a JSONB row; the two small files can be JSONB. Baseline is only read at export/reseed time.
- **`dash_field`** — editable-field registry derived at seed: `id, file, field_path (pointer), natural_key, group_key, section_key, field_kind, baseline_value, baseline_version_id`. `UNIQUE(file, field_path)`. For blueprint rows also parse `group_key` into `venus_sign, moon_sign, element` columns to drive the star-sign facet filters. This holds `baseline_value` so **rendering and search never load the big blob**. Search is client-side fuzzy by default (see the search row above), so **no trigram index is required for v1**. Only if you adopt the server FTS fallback: add a `tsvector` generated column over `coalesce(current_value, baseline_value)` with a GIN index, and `CREATE EXTENSION IF NOT EXISTS pg_trgm;` **only** if you additionally want trigram similarity for typo-tolerant server ranking (neither `pg_trgm` nor FTS config is enabled by any existing migration — add explicitly if used).
- **`dash_override`** — current edited value: `field_id PK, current_value, version int, updated_by, updated_at`. (No trigram index in v1 — search is client-side; add a GIN `tsvector` index here too only if you take the server-FTS fallback.)
- **`dash_edit_log`** — append-only history (powers the diff/changes feed & version history): `id, field_id, field_path, file, group_key, old_value, new_value, version, edited_by, edited_at DESC index`.
- **`dash_content_versions`** — one row per Export: `version_id (identity), created_at, editor, label, manifest jsonb, file_sha256 jsonb, changed_field_count, status`. `version_id` is the "what version did I download" answer.
- **`dash_login_attempts`** — persistent brute-force guard: `id, username, ip, window_start, count`. Checked + incremented in the login route so the rate-limit survives serverless cold starts (see auth row below).

Mirror existing DDL conventions from `supabase/migrations/001_initial_schema.sql` (`pgcrypto`, `gen_random_uuid()`, `timestamptz DEFAULT now()`, RLS per table). Name the migration **`012_content_dashboard.sql`** (existing files run 001–011) — not `dash_001_…` — to keep ordering obvious.

---

## Requirement → implementation map

| Requirement | How |
|---|---|
| Show all paragraphs (like review_tool.py) | Server Component renders `dash_field` ⟕ `dash_override` grouped by file → cluster/card/sign → section. Port sidebar + section-card layout + palette from `tools/review_tool.py`. |
| Search a word → filter paragraphs | **Primary = client-side fuzzy index.** The full field registry (`dash_field` ⟕ `dash_override`, a few MB of prose across ~15–20k short rows) is already loaded to render the editor, so search runs **in-memory in the browser** with a ranked fuzzy matcher (**uFuzzy**, or Fuse.js) — instant, relevance-**ranked**, typo-tolerant, multi-word, zero per-keystroke round-trip. `SearchBar` filters live and lists matches with cluster/section context + jump link. Debounce ~120 ms; start matching at **≥2 chars** (fuzzy ranks, so no trigram 3-char floor needed). **Server fallback for scale:** if the registry ever outgrows comfortable client memory, fall back to `GET /api/content?q=` backed by Postgres **full-text search** (`tsvector` + `websearch_to_tsquery` + `ts_rank` for ranking) — *not* raw substring `ILIKE`, which gives no ranking or typo tolerance. |
| **Filter by star sign / element** | Cluster `group_key` is `venus_<sign>__moon_<sign>__<element>_dominant`. Parse it into three facets — **Venus sign / Moon sign / Element** — and offer multi-select filtering in the sidebar (not just a flat cluster list). |
| Inline edit, **no edit button** | `EditableField.tsx`: always-on `<textarea>` (`white-space: pre-wrap`, auto-grow) prefilled with the value including its `\n\n` breaks. |
| Per-paragraph Save | One Save button **bottom-right of each box**, disabled until dirty; save → Server Action → upsert `dash_override` + append `dash_edit_log`; flips to "Saved ✓". |
| **Per-paragraph version history (primary UI)** | Each `EditableField` has its own **"history" disclosure/dropdown** that expands to show *that field's* prior versions from `dash_edit_log` — each entry rendered inline with the `WordDiff` word-level highlight (amends highlighted) + which user made it + timestamp. This is the on-the-box dropdown that was specifically requested. |
| **Revert a paragraph to a prior version** | Every history entry in the per-box dropdown (and the `dash_field` baseline) has a **"Restore" button**. Restore is a *forward* write, never a destructive rewind: it writes the chosen `old_value`/`new_value` (or `baseline_value`) as a **new** `dash_override` + a new `dash_edit_log` row (trivial on the append-only log — full history is preserved, and the restore itself is diffable/undoable). Confirm dialog shows the word-diff of current → target before committing. |
| Paragraph info/metadata | Port review_tool.py's per-section metadata + live lint (word count 50–150, banned words, hedging phrases, US spellings, 2nd-person, declarative) from `tools/review_tool.py` lines ~60–146 into `lib/content/lint.ts`. Warnings inform, never block. |
| Versioning | `dash_edit_log` (append-only) = per-field history; `dash_content_versions` = per-Export snapshot with incrementing `version_id`. |
| Diff UI (what/who/when) | Two surfaces off the same `dash_edit_log`: (a) the **per-box history dropdown** above (the primary, requested one); (b) a global `/changes` page — reverse-chron feed joined to `dash_users`, `WordDiff` (insert green / delete struck red), filter by author + file. |
| Light login (maria/ash) | `dash_users` + argon2; `/api/auth/login` verifies → `jose`-signed httpOnly `Secure SameSite=Lax` cookie; `middleware.ts` gates every page + `/api/*`. Public URL ⇒ this is the real security boundary: strong random passwords, `SESSION_SECRET` (32B), RLS deny-all so a leaked publishable key can't touch `dash_` tables, `import 'server-only'` on the service-role client. **Login rate-limit must be persistent** — an in-memory counter does not survive across Vercel serverless instances (each cold start resets it, defeating the limit). Back it with a Supabase table (`dash_login_attempts(username/ip, window_start, count)`, checked/incremented in the login route) or Vercel KV; lock out after N failures per window. |
| Same Supabase instance? | **Yes** — same project, new `dash_`-prefixed tables + one Storage bucket. No second instance needed. |

---

## Export & iOS hand-off (the correctness-critical part)

**Reconstruction:** deep-clone baseline tree, apply overrides at each pointer, serialize with a **per-file formatting profile** (verified byte-faithful):
- `blueprint_narrative_cache.json`: `indent=2, ensure_ascii=false`, **no trailing newline** → byte-identical to committed (matches `backfill_narratives.py`).
- `astrological_style_dataset.json`: `indent=2, ensure_ascii=false`, **trailing `\n`** → byte-identical.
- `TarotCards.json`: **does NOT round-trip** under naive re-dump (129 single-line arrays mixed with multi-line ones). It is currently **indent 4**. **Do a one-time reviewed normalization commit** — normalize to **indent 4** (only inlines the arrays, smallest reviewed diff; the Swift `Codable` decoder is format-agnostic so either indent is safe) `+"\n"` so it becomes idempotent; after that single diff, every export stays minimal. Export profile for this file = `indent=4, ensure_ascii=false, trailing_newline=true`.

**⚠️ Second consumer of the blueprint cache — `inspector/`.** iOS loads `blueprint_narrative_cache.json`, but the `inspector/` tool symlinks its blueprint → **`blueprint_narrative_cache_sg4.json`** (a *separate* file, byte-identical today, same sha256). The export/handoff must not let these silently diverge. **Recommended (default): the Export writes BOTH `blueprint_narrative_cache.json` and `blueprint_narrative_cache_sg4.json` with identical bytes**, so the inspector never serves stale content — zero repo/symlink surgery, matches the "SG-4 = V2" promotion. (Alternative to decide later: collapse the inspector symlink onto the single canonical file.) Add both files to the handoff checklist.

**Guards:** never `sort_keys`; assert top-level keys and `schema_version:2` unchanged; assert that a **zero-override export is byte-identical to the baseline** (structural-drift tripwire — proves all 576 clusters reproduce exactly).

**Version stamp = sidecar `manifest.json`, NOT in-file.** Verified from `NarrativeCacheLoader.swift:112-119`: a top-level **object** key would be ingested as a phantom 577th cluster (unsafe); only a scalar is silently skipped. So keep content files pristine and put version/editor/sha256/changed-fields in a `manifest.json` that **extends the existing backup manifest schema** (`tools/backup_content_sources.py` — keep `files[]{repo_path,bytes,sha256}`, add `kind, version_id, editor, changed_fields[]`, per-file `serializer` profile). Download bundle = 3 files + manifest.

**Hand-off checklist for Ash:** (1) Export in dashboard → download bundle; (2) **backup gate first** — `python3 tools/backup_content_sources.py backup --domain all --label export-vNN` (same rule the Python amend scripts enforce); (3) drop files at canonical paths — `data/style_guide/blueprint_narrative_cache.json` **and** `data/style_guide/blueprint_narrative_cache_sg4.json` (identical bytes, keeps the `inspector/` consumer in sync), `data/style_guide/astrological_style_dataset.json`, and `Cosmic Fit/Resources/TarotCards.json` (real file, overwrite in place); (4) Resources symlinks resolve at build — no Xcode change; (5) build & verify log `Loaded 576 archetype clusters (schema v2)`; (6) commit the files + manifest.

**Reseed/reconcile policy** (guards against `backfill_narratives.py` / `content_audit_apply.py` regenerating files out-of-band): on any regenerated file, insert a new `dash_baseline` version and, per existing override, compare its stored baseline value to the new baseline at the same pointer — unchanged ⇒ carry forward; changed ⇒ mark `needs_review` (side-by-side in UI, human picks); pointer gone ⇒ `orphaned` for manual re-anchor via natural key. Supabase wins for overridden prose; generators win for structure and un-edited prose.

---

## Vercel deployment
- Vercel project → **Root Directory = `content-dashboard`** (Next.js preset auto-detected). Production branch `main`, auto-deploy on push.
- Env vars (server-only, **not** `NEXT_PUBLIC_`): reuse the repo-standard names `SUPABASE_URL` and **`SUPABASE_SERVICE_ROLE_KEY`** (the established name across existing code — avoid `SUPABASE_SECRET_KEY`); add `SESSION_SECRET`. Anon/publishable key not needed.
- **Ignored Build Step:** `git diff --quiet HEAD^ HEAD -- content-dashboard` so iOS/content commits don't trigger redeploys (exports touch `data/`, not `content-dashboard/`).
- **`.gitignore` additions:** `content-dashboard/{node_modules,.next,.vercel,.env.local}`.
- `content-dashboard/` sits outside `Cosmic Fit/`, so the Xcode 16 synced folder won't bundle it. Confirmed safe.

---

## Build order
1. Scaffold `content-dashboard/` Next.js app + `.gitignore` entries; port palette/layout from `tools/review_tool.py`.
2. `012_content_dashboard.sql` migration; create `dash-baselines` Storage bucket.
3. `lib/content/{paths,schema}.ts` — field enumerators + pointer utils, built to the **v1 editable-field scope per file** above (blueprint 16 sections + facets; TarotCards prose keys only; astro-dataset whole-array blocks *or* deferred — lock the choice here so seed matches).
4. `scripts/seed.ts` + `scripts/seed-users.ts`; run against Supabase (import baselines, build field registry, seed maria/ash). **Seed from today's normalized V2 `blueprint_narrative_cache.json` (with the capitalization + hygiene fixes), never an older/`_pre_sg4` cache** — verify the seeded baseline's sha256 matches the current committed file before proceeding. Coordinate with the other dev that this V2 file is the tool's source-of-truth.
5. Auth: `middleware.ts`, `lib/auth/*`, `/api/auth/*`, `/login`, **persistent login rate-limit** (`dash_login_attempts` or Vercel KV).
6. Editor read path: `/`, `/editor/[file]/[groupKey]`, `EditableField` (Save bottom-right), `SearchBar` (**client-side fuzzy over the loaded field registry** — uFuzzy/Fuse.js, ranked + typo-tolerant, ~120 ms debounce, ≥2 chars), Venus/Moon/Element facet filters, ported `lib/content/lint.ts`.
7. Save path: field Server Action → `dash_override` upsert (optimistic `version` check) + `dash_edit_log` append.
8. `WordDiff` + **per-box history dropdown in `EditableField`** (primary version UI) + **per-entry "Restore" (forward-write revert)** + global `/changes` feed.
9. `lib/content/export.ts` + `/api/export` (per-file profiles incl. TarotCards indent 4; **writes both blueprint files**; guards + manifest); **one-time TarotCards normalization commit**.
10. Connect Vercel (root dir, env, ignored build step); first deploy; end-to-end test.
11. **Decommission `tools/review_tool.py`** (see *Decommission the old review tool*) — only after step 10 verification passes.

---

## Verification
- **Round-trip integrity:** seed → export with zero edits → assert each exported file is **byte-identical** (sha256) to the committed baseline (after the one-time TarotCards normalization), and that the two blueprint files (`…cache.json` and `…cache_sg4.json`) come out identical to each other. This is the core safety test.
- **Per-box history:** after two edits to one field by different users, the field's history dropdown shows both, newest first, with the word-diff and correct author each.
- **Revert:** click "Restore" on an earlier history entry → confirm dialog shows current→target diff → after commit the field value equals the target, a **new** `dash_edit_log` row records the restore (nothing deleted), and the restore is itself reversible.
- **Search quality:** a typo'd or partial query (e.g. `velvit`, `tailor`) still surfaces the intended paragraphs, **ranked** by relevance; 1-char input doesn't filter, ≥2 chars does; results are instant (no per-keystroke network call).
- **Edit → export → build:** change one paragraph in the dashboard → export → drop into repo → `git diff` shows only that field changed → build the iOS app in Xcode → confirm the reworded copy appears in the Style Guide screen and the log reads `Loaded 576 archetype clusters (schema v2)`.
- **Auth gate:** unauthenticated request to any page/`/api/*` → redirected/401; valid login sets cookie; logout clears it.
- **Rate-limit persistence:** N failed logins lock the account/IP for the window **even across separate serverless invocations** (simulate by hitting the login route repeatedly; the counter must not reset per cold start).
- **Search:** query a known word → only matching paragraphs shown, with cluster/section context.
- **Tarot/dataset editing:** open a TarotCards card and (if in v1 scope) an astro-dataset group → confirm only the intended prose fields are editable, structured/list items are read-only, and an edit round-trips through export byte-faithfully for that file.
- **Diff feed:** after an edit, `/changes` shows the correct old→new word diff, author, timestamp.
- **Concurrency:** two sessions edit the same field; the second save hits the optimistic `version` guard (409) and prompts reload rather than silently clobbering — the append-only log retains both values.

## Open follow-ups (not blockers)
- Astro-dataset array editing is now scoped in **v1 editable-field scope per file** (whole-array block edit, or defer the file to v2) — decide before seeding, no longer open-ended.
- Password rotation / optional second gate (Vercel project password or TOTP) if you later want more assurance.
- Live presence (two editors seeing each other in real time) is **out of v1** — the optimistic `version` 409 guard is the safety net for the 2-user case; revisit only if concurrent editing becomes common.

## Decommission the old review tool
`tools/review_tool.py` (local Flask, read-only, blueprint-only) is **superseded** by this dashboard, which is a full reimplementation in a different stack (TypeScript/React, not Python/Flask) — no code is literally shared; what carries over is the **palette/layout** and the **lint rules** (ported into `lib/content/lint.ts`). Do **not** keep both once the dashboard passes end-to-end verification.
- **Safe to retire:** its state files `pause_signal.json` / `review_notes.json` have **no other consumers** — verified the SG pipeline's `content_audit.py` / `content_audit_tool.py` use *separately named* files (`audit_pause_signal.json`, `audit_review_notes.json`), not review_tool's.
- **Decommission step (after dashboard verification):** delete `tools/review_tool.py` + its `review_notes.json` / `pause_signal.json` (and any now-orphaned `tools/requirements.txt` Flask entry if unused elsewhere); leave a one-line pointer in `tools/README.md` noting the dashboard replaced it. This is step 11 in the build order.
