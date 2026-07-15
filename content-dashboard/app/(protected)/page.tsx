export const dynamic = 'force-dynamic';

export default function Home() {
  return (
    <div>
      <div className="top-bar">
        <div className="crumbs">
          Welcome<span className="dim"> — pick a cluster or search</span>
        </div>
      </div>
      <div className="section-card">
        <p style={{ marginBottom: 12 }}>
          Use the sidebar to browse <strong>Blueprint</strong> clusters (filter by Venus / Moon /
          Element) or <strong>Tarot</strong> cards, or search any word — matching is instant, ranked,
          and typo-tolerant.
        </p>
        <p style={{ marginBottom: 12 }}>
          Open a cluster or card, edit a paragraph directly in its box, and press <strong>Save</strong>{' '}
          (bottom-right of each box). Every save is versioned — open a box&apos;s <strong>History</strong>{' '}
          to see prior versions with a word-diff, who changed it, and when, and <strong>Restore</strong>{' '}
          any of them.
        </p>
        <p>
          When you&apos;re ready to ship copy into an iOS build, use <strong>Export bundle</strong> in the
          sidebar. The <strong>Astrological Style Dataset</strong> is shown read-only — it feeds the
          Style Guide generator rather than being displayed copy, so it can&apos;t be edited here yet.
        </p>
      </div>
    </div>
  );
}
