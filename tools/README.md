# Cosmic Fit — developer tools

Python utilities for datasets, Style Guide narrative QA, and regression helpers. **Not** used by the iOS app build.

Install dependencies once (from the **repository root**):

```bash
pip install -r tools/requirements.txt
```

Run scripts from the **repository root**. Canonical Style Guide JSON lives under **`data/style_guide/`** (see **`data/style_guide/README.md`**).

```bash
python3 tools/validate_dataset.py
python3 tools/review_tool.py --port 8420
```

**SynthID single-image drop** (needs `scripts/.venv` for torch/diffusers):

```bash
cd scripts && source .venv/bin/activate
pip install flask   # once, if not already installed in this venv
python ../tools/synthid_drop_tool.py --port 8421
```

Opens http://localhost:8421 — drag an image, submit. Uses the same settings as `run_full_synthid_removal.sh` (0.04 × 3 passes, 768px tiles, 128 overlap). All synthid I/O is under repo-root `Resources/` (outside the Xcode bundle): drop tool → `synthid_drop_inbox/`, `synthid_drop_desynthid/`, `synthid_drop_state/`; batch originals → `originals/` / `originals_desynthid/`; backups & candidates → `.synthid_backups/`, `.synthid_baseline/`, `.synthid_candidates/`, `.synthid_originals_backup/`, `.synthid_originals_candidates/`.

Full catalogue and behaviour are documented in the root **`README.md`** (§2.1–2.2).

**Daily Fit sign-energy validation** (requires local inspector on `127.0.0.1:7777`):

```bash
cd inspector && ./run-inspector.sh   # separate terminal
python3 tools/sign_energy_inspector_harness.py
```

Writes `docs/fixtures/sign_audit_downstream_post_phase1.txt`, refreshes `sign_audit_inspector_evidence.json` and `sign_energy_matrix_baseline.txt`.
