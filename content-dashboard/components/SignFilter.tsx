'use client';

export type Facets = { venus: Set<string>; moon: Set<string>; element: Set<string> };
export type FacetDim = keyof Facets;

/** Venus / Moon / Element multi-select facet chips for blueprint clusters. */
export default function SignFilter({
  available,
  selected,
  onToggle,
  onClear,
}: {
  available: { venus: string[]; moon: string[]; element: string[] };
  selected: Facets;
  onToggle: (dim: FacetDim, value: string) => void;
  onClear: () => void;
}) {
  const anySelected = selected.venus.size + selected.moon.size + selected.element.size > 0;
  const dims: { dim: FacetDim; label: string; values: string[] }[] = [
    { dim: 'venus', label: 'Venus', values: available.venus },
    { dim: 'moon', label: 'Moon', values: available.moon },
    { dim: 'element', label: 'Element', values: available.element },
  ];

  return (
    <div>
      {dims.map(({ dim, label, values }) => (
        <div className="facet-group" key={dim}>
          <div className="facet-title">{label}</div>
          <div className="facet-chips">
            {values.map((v) => (
              <span
                key={v}
                className={`chip ${selected[dim].has(v) ? 'on' : ''}`}
                onClick={() => onToggle(dim, v)}
                role="button"
                tabIndex={0}
                onKeyDown={(e) => (e.key === 'Enter' || e.key === ' ') && onToggle(dim, v)}
              >
                {v}
              </span>
            ))}
          </div>
        </div>
      ))}
      {anySelected && (
        <div className="facet-group">
          <span className="chip" onClick={onClear} role="button" tabIndex={0}>
            ✕ Clear filters
          </span>
        </div>
      )}
    </div>
  );
}
