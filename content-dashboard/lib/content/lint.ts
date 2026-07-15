/**
 * Copy-quality lint — ported verbatim from tools/review_tool.py
 * (validate_paragraph + BANNED_WORDS / HEDGING_PHRASES / AMERICAN_SPELLINGS).
 *
 * Warnings INFORM, they never block a save. The UI decides which tags to show
 * per field kind (the 50–150-word rule only meaningfully applies to full
 * paragraphs, not one-line intros/closings).
 */

export const BANNED_WORDS = [
  'delve', 'tapestry', 'resonate', 'elevate', 'curate', 'embark',
  'multifaceted', 'realm', 'robust', 'leverage', 'utilize', 'harness',
  'holistic', 'synergy', 'paradigm', 'nuanced', 'myriad',
];

export const HEDGING_PHRASES = ['you might', 'perhaps', 'maybe', 'possibly'];

export const AMERICAN_SPELLINGS: Record<string, string> = {
  color: 'colour',
  center: 'centre',
  organize: 'organise',
  realize: 'realise',
  recognize: 'recognise',
  favor: 'favour',
  behavior: 'behaviour',
  honor: 'honour',
  labor: 'labour',
};

export interface LintResult {
  wordCount: number;
  lengthOk: boolean;
  banned: string[];
  hedging: string[];
  secondPerson: boolean;
  declarative: boolean;
  american: string[]; // formatted "us → uk"
  passed: boolean;
}

/** Faithful port of review_tool.py's validate_paragraph. */
export function validateParagraph(text: string): LintResult {
  const words = text.split(/\s+/).filter((w) => w.length > 0);
  const wc = words.length;
  const lower = text.toLowerCase();

  const banned = BANNED_WORDS.filter((w) => lower.includes(w));
  if (lower.includes('landscape')) banned.push('landscape');

  const hedging = HEDGING_PHRASES.filter((p) => lower.includes(p));
  const secondPerson = ['You', 'Your', 'you', 'your'].some((m) => text.includes(m));
  const declarative = !text.trim().endsWith('?');

  const american: string[] = [];
  for (const [us, uk] of Object.entries(AMERICAN_SPELLINGS)) {
    if (lower.includes(us)) american.push(`${us} → ${uk}`);
  }

  const lengthOk = wc >= 50 && wc <= 150;
  const passed =
    lengthOk &&
    banned.length === 0 &&
    hedging.length === 0 &&
    secondPerson &&
    declarative;

  return { wordCount: wc, lengthOk, banned, hedging, secondPerson, declarative, american, passed };
}

/**
 * Placeholder tokens like `{texture_good_1}` are resolved at runtime by the iOS
 * app from the cluster's structured lists. If an edit drops one the baseline
 * had, the app would render a literal gap — so we surface it as a warning
 * (never a block). Returns the sorted unique `{token}` set found in `text`.
 */
export function extractPlaceholders(text: string): string[] {
  const found = new Set<string>();
  for (const m of text.matchAll(/\{[a-zA-Z0-9_]+\}/g)) found.add(m[0]);
  return [...found].sort();
}

/** Placeholders present in `baseline` but missing from `edited`. */
export function missingPlaceholders(baseline: string, edited: string): string[] {
  const have = new Set(extractPlaceholders(edited));
  return extractPlaceholders(baseline).filter((t) => !have.has(t));
}
