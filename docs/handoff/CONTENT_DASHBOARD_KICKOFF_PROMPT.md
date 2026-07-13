# Content Dashboard — Kickoff Prompt

Hand this to the AI developer building the dashboard. It scopes the first,
locally-testable phase. The authoritative spec is
[`content_dashboard_plan.md`](content_dashboard_plan.md).

**Ownership split for this phase:**
- **The AI dev builds:** the `content-dashboard/` Next.js app, the paste-ready
  migration SQL, and the seed scripts — all runnable locally.
- **The owner (Ash) runs:** applying the migration via the Supabase SQL editor,
  creating the Storage bucket, setting env vars, and the eventual Vercel deploy.
- **Architecture note:** the plan keeps all server logic in Next.js route
  handlers / Server Actions on Vercel — **not** in standalone Supabase Edge
  Functions. That is deliberate for local testability. If a variant using
  Supabase Edge Functions for the mutations is wanted instead, raise it with the
  owner first; do not switch unilaterally.

---

## Prompt

You are building the **Content Dashboard** for the Cosmic Fit app. The complete,
authoritative spec is at **`docs/handoff/content_dashboard_plan.md`** — read it
in full before writing any code. It is the source of truth; this prompt only
scopes *which slice* you build now and how it must be locally testable.

**Your scope this phase:** build the `content-dashboard/` Next.js app so it runs
locally (`npm run dev`) against the owner's existing hosted Supabase project,
plus the paste-ready SQL migration and seed scripts. **Do NOT deploy to Vercel
and do NOT provision Supabase** — the owner does both by hand (pastes the SQL
into the Supabase SQL editor, creates the Storage bucket, sets env vars,
connects Vercel). Build steps **1–9** of the plan's Build Order; stop before
step 10 (Vercel) and step 11 (decommission).

**Deliverables:**
1. `content-dashboard/` — Next.js 14 App Router + TypeScript app exactly per the
   plan's directory layout, stack (`@supabase/supabase-js` service-role
   server-only, `jose`, argon2, `jsdiff`, `@leeoniya/ufuzzy`), and Supabase data
   model. No component library; port the palette/layout/fonts and the lint rules
   from `tools/review_tool.py` into `lib/content/lint.ts`.
2. `content-dashboard/supabase/migrations/012_content_dashboard.sql` — a single
   **copy-paste-ready** migration (mirrors conventions in
   `supabase/migrations/001_initial_schema.sql`: `pgcrypto`,
   `gen_random_uuid()`, `timestamptz DEFAULT now()`, RLS-enabled-with-no-policies
   deny-all per table). All `dash_*` tables incl. `dash_login_attempts`. No
   `pg_trgm`/FTS in v1 (search is client-side).
3. `scripts/seed.ts` + `scripts/seed-users.ts` — import the three JSON files into
   baselines + field registry, and insert `maria`/`ash` (argon2 hashes,
   passwords from env, never committed).
4. A short `content-dashboard/README.md` with the exact local-run steps (below).
   *(A starter `README.md` and `.env.local.example` already exist in
   `content-dashboard/` — keep them accurate as you build.)*

**Local-testability contract (this is the acceptance bar):**
- Runs with `npm install && npm run dev` on `localhost`, driven by `.env.local`
  holding `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` (this canonical name — the
  same secret the repo's Python tooling stores as `SUPABASE_SECRET_KEY`; do not
  invent new names), `SESSION_SECRET`, and the seed passwords. Ship
  `.env.local.example`; never commit real secrets. Add
  `content-dashboard/{node_modules,.next,.vercel,.env.local}` to `.gitignore`.
- Because the owner applies the migration manually, **order the handoff clearly
  in the README**: (a) paste `012_content_dashboard.sql` into the Supabase SQL
  editor; (b) create the `dash-baselines` Storage bucket; (c) set `.env.local`;
  (d) `npm run seed` then `npm run seed:users`; (e) `npm run dev`. The seed
  script must **fail loudly if the migration/bucket aren't present** rather than
  half-succeeding.
- End-to-end, on localhost, the owner must be able to: log in as maria/ash →
  browse blueprint clusters with Venus/Moon/Element facets → fuzzy-search
  (ranked, typo-tolerant, ≥2 chars, no per-keystroke network) → edit a paragraph
  in an always-on textarea → Save (per-box, bottom-right) → see it in the per-box
  history dropdown with word-diff + author + timestamp → **Restore** a prior
  version → view the global `/changes` feed → **Export** a bundle and confirm the
  round-trip guard passes.

**Non-negotiable guardrails (from the plan — get these exactly right):**
- **Seed source-of-truth:** seed from **today's committed V2**
  `data/style_guide/blueprint_narrative_cache.json` (has the capitalization +
  hygiene fixes), never a `_pre_sg4`/older cache. Before seeding, assert the
  seeded baseline's sha256 matches the current committed file; abort on mismatch.
- **Export is correctness-critical:** deep-clone the baseline tree, apply
  overrides by JSON pointer, serialize with the **per-file formatting profiles**
  in the plan (blueprint: indent 2, no trailing newline; astro-dataset: indent 2,
  trailing `\n`; TarotCards: indent 4, trailing `\n` — and produce the one-time
  TarotCards normalization commit as a separate reviewed diff). **A zero-override
  export must be byte-identical (sha256) to the committed baseline** — implement
  this as an automated test; it's the core safety net. Export **writes both**
  `blueprint_narrative_cache.json` and `blueprint_narrative_cache_sg4.json` with
  identical bytes. Never `sort_keys`. Version/editor/sha256/changed-fields go in
  a sidecar `manifest.json`, never inside the content files.
- **Security:** service-role client is `import 'server-only'`; `middleware.ts`
  gates every page and `/api/*`; httpOnly `Secure SameSite=Lax` jose cookie; RLS
  deny-all on all `dash_*` tables; **persistent** login rate-limit via
  `dash_login_attempts` (must survive process restarts, not in-memory).
- **v1 editable-field scope per file:** follow the plan's "v1 editable-field
  scope per file" section exactly — blueprint full; TarotCards prose keys only
  (lists read-only); astro-dataset whole-array block-edit **or** deferred (flag
  the choice to the owner before seeding). Prose only — never add/remove
  structured list items.

**Do NOT:** deploy anything; write into the repo's real `data/` or
`Cosmic Fit/Resources/` files (Export produces a downloadable bundle only — the
owner drops files manually); commit secrets; add tables/extensions beyond the
plan; touch `tools/review_tool.py` (its retirement is a later step the owner
runs).

**Working method:** confirm your understanding of scope and the export
formatting profiles before coding; build in the plan's step order; after the
read path works, verify each guardrail with a runnable check (esp. the
zero-override byte-identical export test) and report what you ran and its
output. Flag any spec ambiguity to the owner rather than guessing — especially
the astro-dataset scope decision and anything about byte-faithful serialization.
