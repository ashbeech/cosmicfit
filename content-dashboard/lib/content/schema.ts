/**
 * Field enumerators + file metadata — the v1 editable-field scope, locked with
 * the owner (see docs/handoff/content_dashboard_plan.md, "v1 editable-field
 * scope per file"):
 *
 *   • blueprint  — per cluster: each of the 16 sections' `.text` (the paragraph)
 *                  and `.sectionIntro`, plus the cluster `closing`. `coreFormula`
 *                  and the structured lists (rankedItems/tests/traps) are READ-ONLY.
 *                  Facets: Venus / Moon / Element parsed from the cluster key.
 *   • tarot      — per card: `description` and each `styleEdits[].title` /
 *                  `styleEdits[].description`. All keyword/theme/symbolism arrays
 *                  and the affinity maps are READ-ONLY. No facets.
 *   • astro      — DEFERRED to v2. It is an ENGINE GENERATION INPUT, not rendered
 *                  copy: editing it changes nothing in the app until the SG
 *                  pipeline re-runs. Shown read-only in the picker; never seeded.
 *
 * Prose only — enumerators only ever emit pointers to string leaves; they never
 * add or remove structured list items.
 */

import { buildPointer } from './paths';

export type FileKey = 'blueprint' | 'tarot' | 'astro';
export type FieldKind = 'paragraph' | 'intro' | 'closing' | 'prose';

/** One editable-field registry record (mirrors dash_field columns). */
export interface FieldRecord {
  file: FileKey;
  fieldPath: string; // RFC-6901 pointer into the baseline tree
  naturalKey: string; // stable, human-readable — used to re-anchor on reseed
  groupKey: string; // cluster key / card name — nav grouping
  sectionKey: string | null;
  fieldKind: FieldKind;
  baselineValue: string;
  venusSign: string | null;
  moonSign: string | null;
  element: string | null;
}

export interface FileMeta {
  key: FileKey;
  label: string;
  repoPath: string;
  editable: boolean;
  facets: boolean;
  /** Deferred files are shown read-only with `note` explaining why. */
  deferred?: boolean;
  note?: string;
}

export const FILES: Record<FileKey, FileMeta> = {
  blueprint: {
    key: 'blueprint',
    label: 'Blueprint — Style Guide copy',
    repoPath: 'data/style_guide/blueprint_narrative_cache.json',
    editable: true,
    facets: true,
  },
  tarot: {
    key: 'tarot',
    label: 'Tarot Cards',
    repoPath: 'Cosmic Fit/Resources/TarotCards.json',
    editable: true,
    facets: false,
  },
  astro: {
    key: 'astro',
    label: 'Astrological Style Dataset',
    repoPath: 'data/style_guide/astrological_style_dataset.json',
    editable: false,
    facets: false,
    deferred: true,
    note: 'Engine generation input — editing requires pipeline regeneration (not yet supported). This file is not user-facing copy; it feeds the Style Guide generator, so changes here do nothing in the app until the pipeline re-runs.',
  },
};

// ─── Blueprint ──────────────────────────────────────────────────────────

/** The 16 sections, in canonical order (ported from tools/review_tool.py). */
export const BLUEPRINT_SECTION_KEYS = [
  'style_core',
  'textures_good',
  'textures_bad',
  'textures_sweet_spot',
  'palette_narrative',
  'occasions_work',
  'occasions_intimate',
  'occasions_daily',
  'hardware_metals',
  'hardware_stones',
  'hardware_tip',
  'accessory_1',
  'accessory_2',
  'accessory_3',
  'pattern_narrative',
  'pattern_tip',
] as const;

/** Display names, ported from tools/review_tool.py SECTION_DISPLAY. */
export const SECTION_DISPLAY: Record<string, string> = {
  style_core: 'Style Core',
  textures_good: 'Textures — Good',
  textures_bad: 'Textures — Bad',
  textures_sweet_spot: 'Textures — Sweet Spot',
  palette_narrative: 'Palette',
  occasions_work: 'Occasions — Work',
  occasions_intimate: 'Occasions — Intimate',
  occasions_daily: 'Occasions — Daily',
  hardware_metals: 'Hardware — Metals',
  hardware_stones: 'Hardware — Stones',
  hardware_tip: 'Hardware — Tip',
  accessory_1: 'Accessory — Paragraph 1',
  accessory_2: 'Accessory — Paragraph 2',
  accessory_3: 'Accessory — Paragraph 3',
  pattern_narrative: 'Pattern',
  pattern_tip: 'Pattern — Tip',
};

/** Parse a cluster key `venus_<s>__moon_<s>__<element>_dominant` into facets. */
export function parseClusterFacets(clusterKey: string): {
  venusSign: string | null;
  moonSign: string | null;
  element: string | null;
} {
  const parts = clusterKey.split('__');
  const venus = parts.find((p) => p.startsWith('venus_'));
  const moon = parts.find((p) => p.startsWith('moon_'));
  const elem = parts.find((p) => p.endsWith('_dominant'));
  return {
    venusSign: venus ? venus.replace('venus_', '') : null,
    moonSign: moon ? moon.replace('moon_', '') : null,
    element: elem ? elem.replace('_dominant', '') : null,
  };
}

function isNonEmptyString(v: unknown): v is string {
  return typeof v === 'string';
}

/**
 * Enumerate blueprint editable fields from the parsed tree.
 * Skips the top-level scalar `schema_version`.
 */
export function enumerateBlueprint(tree: Record<string, any>): FieldRecord[] {
  const out: FieldRecord[] = [];
  for (const clusterKey of Object.keys(tree)) {
    const cluster = tree[clusterKey];
    if (clusterKey === 'schema_version' || cluster == null || typeof cluster !== 'object') {
      continue;
    }
    const facets = parseClusterFacets(clusterKey);

    // Cluster-level `closing` prose.
    if (isNonEmptyString(cluster.closing)) {
      out.push({
        file: 'blueprint',
        fieldPath: buildPointer([clusterKey, 'closing']),
        naturalKey: `${clusterKey}::closing`,
        groupKey: clusterKey,
        sectionKey: 'closing',
        fieldKind: 'closing',
        baselineValue: cluster.closing,
        ...facets,
      });
    }

    // 16 sections × { text, sectionIntro }.
    for (const section of BLUEPRINT_SECTION_KEYS) {
      const node = cluster[section];
      if (node == null || typeof node !== 'object') continue;

      if (isNonEmptyString(node.text)) {
        out.push({
          file: 'blueprint',
          fieldPath: buildPointer([clusterKey, section, 'text']),
          naturalKey: `${clusterKey}::${section}::text`,
          groupKey: clusterKey,
          sectionKey: section,
          fieldKind: 'paragraph',
          baselineValue: node.text,
          ...facets,
        });
      }
      if (isNonEmptyString(node.sectionIntro)) {
        out.push({
          file: 'blueprint',
          fieldPath: buildPointer([clusterKey, section, 'sectionIntro']),
          naturalKey: `${clusterKey}::${section}::sectionIntro`,
          groupKey: clusterKey,
          sectionKey: `${section}.intro`,
          fieldKind: 'intro',
          baselineValue: node.sectionIntro,
          ...facets,
        });
      }
    }
  }
  return out;
}

// ─── Tarot ──────────────────────────────────────────────────────────────

// TarotCards editable prose keys — the EXACT set (plan: "prose fields only,
// structured/list fields read-only"). Verified against every card + styleEdits
// entry:
//   card level    : only `description` is prose (name/imagePath/arcana/suit are
//                   identifiers; keywords/themes/symbolism/reversedKeywords are
//                   lists; energyAffinity/axesAffinity are numeric maps).
//   styleEdits    : `title`, `description`, `dailyRitual`, `wardrobeReflection`
//                   are prose (all four are user-facing — dailyRitual /
//                   wardrobeReflection render as the "Daily Ritual" / "Wardrobe
//                   Reflection" blocks in DailyFitViewController). `variant`
//                   (a "I"/"II"/"III" label) and energyEmphasis/axesEmphasis
//                   (numeric maps) are read-only.
export const TAROT_CARD_PROSE_KEYS = ['description'] as const;
export const TAROT_STYLEEDIT_PROSE_KEYS = [
  'title',
  'description',
  'dailyRitual',
  'wardrobeReflection',
] as const;

/**
 * Enumerate tarot editable fields. The file is an array of 78 cards; pointers
 * use the array index, natural keys use the card name (+ styleEdit variant) so
 * a reseed can re-anchor even if array order shifts.
 */
export function enumerateTarot(tree: any[]): FieldRecord[] {
  const out: FieldRecord[] = [];
  tree.forEach((card, i) => {
    if (card == null || typeof card !== 'object') return;
    const cardName: string = typeof card.name === 'string' ? card.name : `card_${i}`;

    for (const key of TAROT_CARD_PROSE_KEYS) {
      if (isNonEmptyString(card[key])) {
        out.push({
          file: 'tarot',
          fieldPath: buildPointer([i, key]),
          naturalKey: `${cardName}::${key}`,
          groupKey: cardName,
          sectionKey: key,
          fieldKind: 'prose',
          baselineValue: card[key],
          venusSign: null,
          moonSign: null,
          element: null,
        });
      }
    }

    if (Array.isArray(card.styleEdits)) {
      card.styleEdits.forEach((edit: any, j: number) => {
        if (edit == null || typeof edit !== 'object') return;
        const variant: string = typeof edit.variant === 'string' ? edit.variant : String(j);
        for (const key of TAROT_STYLEEDIT_PROSE_KEYS) {
          if (isNonEmptyString(edit[key])) {
            out.push({
              file: 'tarot',
              fieldPath: buildPointer([i, 'styleEdits', j, key]),
              naturalKey: `${cardName}::styleEdit[${variant}]::${key}`,
              groupKey: cardName,
              sectionKey: `styleEdit.${variant}.${key}`,
              fieldKind: 'prose',
              baselineValue: edit[key],
              venusSign: null,
              moonSign: null,
              element: null,
            });
          }
        }
      });
    }
  });
  return out;
}

/** Human label for a field's section within its group (drives the box header). */
export function sectionDisplay(rec: Pick<FieldRecord, 'file' | 'sectionKey' | 'fieldKind'>): string {
  if (rec.file === 'blueprint') {
    if (rec.fieldKind === 'closing') return 'Closing';
    const base = rec.sectionKey?.replace('.intro', '') ?? '';
    const name = SECTION_DISPLAY[base] ?? base;
    return rec.fieldKind === 'intro' ? `${name} — Intro` : name;
  }
  return rec.sectionKey ?? 'Prose';
}
