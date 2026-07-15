/**
 * RFC-6901 JSON-pointer utilities.
 *
 * Every editable field is addressed by a JSON pointer into the frozen baseline
 * tree. Export = deep-clone baseline → setByPointer(pointer, value) per override
 * → serialize with the file's exact formatting profile. Pointers therefore must
 * round-trip losslessly, including the `~0`/`~1` escapes.
 */

/** Escape a single reference token per RFC-6901 (`~` → `~0`, `/` → `~1`). */
export function escapeToken(token: string): string {
  return token.replace(/~/g, '~0').replace(/\//g, '~1');
}

/** Inverse of {@link escapeToken}. Order matters: `~1` before `~0`. */
export function unescapeToken(token: string): string {
  return token.replace(/~1/g, '/').replace(/~0/g, '~');
}

/** Build a pointer string from raw (unescaped) tokens. `[]` → `""` (whole doc). */
export function buildPointer(tokens: Array<string | number>): string {
  if (tokens.length === 0) return '';
  return '/' + tokens.map((t) => escapeToken(String(t))).join('/');
}

/** Parse a pointer string into its raw (unescaped) tokens. */
export function parsePointer(pointer: string): string[] {
  if (pointer === '') return [];
  if (pointer[0] !== '/') {
    throw new Error(`Invalid JSON pointer (must start with "/"): ${pointer}`);
  }
  return pointer.slice(1).split('/').map(unescapeToken);
}

/** Structured deep clone of a JSON-safe value. */
export function deepClone<T>(value: T): T {
  // structuredClone is available in Node 17+ and modern browsers; JSON fallback
  // is fine because these trees are pure JSON (no Dates/Maps/functions).
  if (typeof structuredClone === 'function') return structuredClone(value);
  return JSON.parse(JSON.stringify(value)) as T;
}

/** Read the value at a pointer, or `undefined` if any segment is missing. */
export function getByPointer(tree: unknown, pointer: string): unknown {
  const tokens = parsePointer(pointer);
  let node: any = tree;
  for (const tok of tokens) {
    if (node == null || typeof node !== 'object') return undefined;
    node = node[tok];
  }
  return node;
}

/**
 * Set the value at a pointer, mutating `tree` in place. Throws if a parent
 * segment is missing (a valid override must anchor to an existing node — we
 * never create new structure, matching the "prose only, no add/remove" rule).
 */
export function setByPointer(tree: unknown, pointer: string, value: unknown): void {
  const tokens = parsePointer(pointer);
  if (tokens.length === 0) {
    throw new Error('Cannot set the whole document via pointer ""');
  }
  let node: any = tree;
  for (let i = 0; i < tokens.length - 1; i++) {
    const tok = tokens[i];
    if (node == null || typeof node !== 'object' || !(tok in node)) {
      throw new Error(`Pointer parent segment missing: ${pointer} (at "${tok}")`);
    }
    node = node[tok];
  }
  const last = tokens[tokens.length - 1];
  if (node == null || typeof node !== 'object' || !(last in node)) {
    throw new Error(`Pointer leaf segment missing: ${pointer} (at "${last}")`);
  }
  node[last] = value;
}
