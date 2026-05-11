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

Full catalogue and behaviour are documented in the root **`README.md`** (§2.1–2.2).
