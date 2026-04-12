#!/usr/bin/env python3
"""
Cosmic Fit — Narrative Review Tool (WP3)

A local-only web UI for reviewing AI-generated Blueprint paragraphs.
Conforms to _reference/narrative_review_tool_spec.md.

Usage:
    python3 review_tool.py [--cache blueprint_narrative_cache.json] [--port 8420]

Stack: Python Flask, dark theme, stateless server.
All persistent state lives in blueprint_narrative_cache.json and review_notes.json.
"""

import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

try:
    from flask import Flask, render_template_string, request, jsonify
except ImportError:
    print("ERROR: Flask not installed. Install with: pip install flask")
    sys.exit(1)


# ─── Constants ─────────────────────────────────────────────────────────

SECTION_KEYS = [
    "style_core",
    "textures_good", "textures_bad", "textures_sweet_spot",
    "palette_narrative",
    "occasions_work", "occasions_intimate", "occasions_daily",
    "hardware_metals", "hardware_stones", "hardware_tip",
    "accessory_1", "accessory_2", "accessory_3",
    "pattern_narrative", "pattern_tip",
]

SECTION_DISPLAY = {
    "style_core": "Style Core",
    "textures_good": "Textures — Good",
    "textures_bad": "Textures — Bad",
    "textures_sweet_spot": "Textures — Sweet Spot",
    "palette_narrative": "Palette",
    "occasions_work": "Occasions — Work",
    "occasions_intimate": "Occasions — Intimate",
    "occasions_daily": "Occasions — Daily",
    "hardware_metals": "Hardware — Metals",
    "hardware_stones": "Hardware — Stones",
    "hardware_tip": "Hardware — Tip",
    "accessory_1": "Accessory — Paragraph 1",
    "accessory_2": "Accessory — Paragraph 2",
    "accessory_3": "Accessory — Paragraph 3",
    "pattern_narrative": "Pattern",
    "pattern_tip": "Pattern — Tip",
}

BANNED_WORDS = [
    "delve", "tapestry", "resonate", "elevate", "curate", "embark",
    "multifaceted", "realm", "robust", "leverage", "utilize", "harness",
    "holistic", "synergy", "paradigm", "nuanced", "myriad",
]

HEDGING_PHRASES = ["you might", "perhaps", "maybe", "possibly"]

AMERICAN_SPELLINGS = {
    "color": "colour", "center": "centre", "organize": "organise",
    "realize": "realise", "recognize": "recognise", "favor": "favour",
    "behavior": "behaviour", "honor": "honour", "labor": "labour",
}

app = Flask(__name__)

CACHE_PATH = "blueprint_narrative_cache.json"
REVIEW_PATH = "review_notes.json"
PAUSE_PATH = "pause_signal.json"


# ─── Data Access ───────────────────────────────────────────────────────

def load_cache() -> dict:
    if not os.path.exists(CACHE_PATH):
        return {}
    with open(CACHE_PATH) as f:
        return json.load(f)


def load_review_notes() -> dict:
    if not os.path.exists(REVIEW_PATH):
        return {}
    with open(REVIEW_PATH) as f:
        return json.load(f)


def save_review_notes(notes: dict):
    with open(REVIEW_PATH, "w") as f:
        json.dump(notes, f, indent=2, ensure_ascii=False)


def is_paused() -> bool:
    if not os.path.exists(PAUSE_PATH):
        return False
    try:
        with open(PAUSE_PATH) as f:
            data = json.load(f)
        return data.get("paused", False)
    except (json.JSONDecodeError, IOError):
        return False


# ─── Validation ────────────────────────────────────────────────────────

def validate_paragraph(text: str) -> dict:
    words = text.split()
    wc = len(words)
    lower = text.lower()

    found_banned = [w for w in BANNED_WORDS if w in lower]
    if "landscape" in lower:
        found_banned.append("landscape")

    found_hedging = [p for p in HEDGING_PHRASES if p in lower]
    has_second = any(m in text for m in ["You", "Your", "you", "your"])
    has_declarative = not text.strip().endswith("?")

    found_american = []
    for us, uk in AMERICAN_SPELLINGS.items():
        if us in lower:
            found_american.append(f"{us} → {uk}")

    ok = (50 <= wc <= 150 and len(found_banned) == 0
          and len(found_hedging) == 0 and has_second and has_declarative)

    return {
        "word_count": wc,
        "length_ok": 50 <= wc <= 150,
        "banned": found_banned,
        "hedging": found_hedging,
        "second_person": has_second,
        "declarative": has_declarative,
        "american": found_american,
        "passed": ok,
    }


# ─── HTML Template ─────────────────────────────────────────────────────

TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Cosmic Fit — Narrative Review</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=DM+Serif+Text&family=PT+Serif:wght@400;700&display=swap" rel="stylesheet">
<style>
:root {
    --bg: #DEDEDE; --surface: #fff; --card: #f4f4f5;
    --accent: #0D0E1F; --accent-lilac: #7E69E6;
    --text: #000210; --dim: #6A6A73; --border: rgba(0,2,16,0.12);
    --green: #2e7d32; --yellow: #e6a100; --red: #c62828;
}
* { box-sizing: border-box; margin: 0; padding: 0; }
body { background: var(--bg); color: var(--text); font: 14px/1.6 'PT Serif', Georgia, serif; display: flex; height: 100vh; }

.sidebar { width: 280px; background: var(--surface); overflow-y: auto; flex-shrink: 0; border-right: 1px solid var(--border); }
.sidebar h1 { padding: 16px 16px 0px 16px; font-family: 'DM Serif Text', Georgia, serif; color: var(--text); }
.sidebar h2 { padding: 0px 16px 16px 16px; font-size: 16px; font-family: 'DM Serif Text', Georgia, serif; border-bottom: 1px solid var(--border); color: var(--text); }
.cluster-item { padding: 10px 16px; cursor: pointer; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; transition: background 0.15s; }
.cluster-item:hover { background: var(--card); }
.cluster-item.active { background: var(--card); border-left: 3px solid var(--accent); }
.badge { font-size: 11px; padding: 2px 8px; border-radius: 10px; background: var(--bg); color: var(--dim); font-weight: 600; }
.badge.complete { background: var(--green); color: #fff; }

.main { flex: 1; overflow-y: auto; padding: 24px; }
.top-bar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; padding: 16px; background: var(--surface); border-radius: 8px; border: 1px solid var(--border); }
.stats { display: flex; gap: 24px; font-size: 13px; }
.stat-label { color: var(--dim); font-size: 11px; text-transform: uppercase; letter-spacing: 0.04em; }
.stat-value { font-weight: 700; font-size: 18px; font-family: 'DM Serif Text', Georgia, serif; }

.section-card { background: var(--surface); border-radius: 8px; padding: 20px; margin-bottom: 16px; border: 1px solid var(--border); }
.section-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.section-name { font-size: 15px; font-weight: 600; font-family: 'DM Serif Text', Georgia, serif; }
.section-text { padding: 12px; background: var(--card); border-radius: 6px; font-size: 14px; line-height: 1.7; white-space: pre-wrap; margin-bottom: 12px; border: 1px solid var(--border); }
.validation { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 12px; }
.val-tag { font-size: 11px; padding: 3px 10px; border-radius: 4px; background: var(--bg); font-weight: 500; }
.val-tag.pass { background: rgba(46,125,50,0.1); color: var(--green); }
.val-tag.fail { background: rgba(198,40,40,0.1); color: var(--red); }
.val-tag.warn { background: rgba(230,161,0,0.1); color: var(--yellow); }

.controls { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
.btn { padding: 6px 16px; border: none; border-radius: 6px; cursor: pointer; font-size: 12px; font-weight: 600; font-family: 'PT Serif', Georgia, serif; transition: opacity 0.15s; }
.btn:hover { opacity: 0.85; }
.btn-approve { background: var(--green); color: #fff; }
.btn-revise { background: var(--yellow); color: #fff; }
.btn-reject { background: var(--red); color: #fff; }
.btn-pause { background: var(--accent); color: #fff; }
.btn-resume { background: var(--green); color: #fff; }
.note-input { flex: 1; padding: 6px 10px; border: 1px solid var(--border); border-radius: 6px; background: var(--card); color: var(--text); font-size: 12px; font-family: 'PT Serif', Georgia, serif; min-width: 200px; }
.note-input:focus { outline: none; border-color: var(--accent-lilac); box-shadow: 0 0 0 2px rgba(126,105,230,0.2); }

.status-badge { font-size: 11px; padding: 2px 8px; border-radius: 4px; font-weight: 600; }
.status-approved { background: var(--green); color: #fff; }
.status-needs_revision { background: var(--yellow); color: #fff; }
.status-rejected { background: var(--red); color: #fff; }

.keyboard-help { position: fixed; bottom: 12px; right: 12px; font-size: 11px; color: var(--dim); background: var(--surface); padding: 8px 12px; border-radius: 6px; border: 1px solid var(--border); }
kbd { background: var(--bg); padding: 1px 6px; border-radius: 3px; font-size: 11px; border: 1px solid var(--border); }
</style>
</head>
<body>

<div class="sidebar">
    <h1><span style="color:var(--accent)">Cosmic Fit</span></h1>
    <h2>Blueprint Paragraph Review Tool</h2>

    <div id="cluster-list"></div>
</div>

<div class="main">
    <div class="top-bar">
        <div class="stats">
            <div><div class="stat-label">Total</div><div class="stat-value" id="stat-total">0</div></div>
            <div><div class="stat-label">Approved</div><div class="stat-value" id="stat-approved" style="color:var(--green)">0</div></div>
            <div><div class="stat-label">Needs Revision</div><div class="stat-value" id="stat-revision" style="color:var(--yellow)">0</div></div>
            <div><div class="stat-label">Rejected</div><div class="stat-value" id="stat-rejected" style="color:var(--red)">0</div></div>
            <div><div class="stat-label">Unreviewed</div><div class="stat-value" id="stat-unreviewed">0</div></div>
        </div>
        <div>
            <button class="btn btn-pause" id="pause-btn" onclick="togglePause()">Pause Pipeline</button>
        </div>
    </div>
    <div id="sections-container"></div>
</div>

<div class="keyboard-help">
    <kbd>a</kbd> approve &nbsp; <kbd>r</kbd> revise &nbsp; <kbd>x</kbd> reject &nbsp;
    <kbd>j</kbd>/<kbd>↓</kbd> next &nbsp; <kbd>k</kbd>/<kbd>↑</kbd> prev &nbsp;
    <kbd>]</kbd> next cluster &nbsp; <kbd>[</kbd> prev cluster
</div>

<script>
let cache = {};
let reviewNotes = {};
let clusters = [];
let currentCluster = null;
let currentSectionIdx = 0;
let paused = false;
const SECTIONS = {{ sections | tojson }};
const SECTION_DISPLAY = {{ display | tojson }};

let cacheFingerprint = '';

async function init() {
    await refreshData(true);
    setInterval(() => refreshData(false), 2000);
}

function fingerprint(obj) {
    let n = 0;
    for (const k in obj) { for (const s in obj[k]) n += obj[k][s].length; }
    return Object.keys(obj).length + ':' + n;
}

async function refreshData(firstLoad) {
    try {
        const res = await fetch('/api/data');
        const data = await res.json();
        const fp = fingerprint(data.cache);
        const changed = fp !== cacheFingerprint;
        cacheFingerprint = fp;
        cache = data.cache;
        reviewNotes = data.review_notes;
        paused = data.paused;
        clusters = Object.keys(cache).sort();
        if (changed || firstLoad) {
            renderClusterList();
            updateStats();
            updatePauseBtn();
            if (firstLoad && clusters.length > 0) selectCluster(clusters[0]);
            else if (currentCluster) renderSections();
        }
    } catch(e) {}
}

function renderClusterList() {
    const el = document.getElementById('cluster-list');
    el.innerHTML = clusters.map(key => {
        const approved = SECTIONS.filter(s => (reviewNotes[key]||{})[s]?.status === 'approved').length;
        const cls = key === currentCluster ? ' active' : '';
        const bcls = approved === 16 ? ' complete' : '';
        return `<div class="cluster-item${cls}" onclick="selectCluster('${key}')">`
            + `<span style="font-size:12px">${key.replaceAll('__', ' · ')}</span>`
            + `<span class="badge${bcls}">${approved}/16</span></div>`;
    }).join('');
}

function selectCluster(key) {
    currentCluster = key;
    currentSectionIdx = 0;
    renderClusterList();
    renderSections();
}

function renderSections() {
    if (!currentCluster) return;
    const entry = cache[currentCluster] || {};
    const el = document.getElementById('sections-container');
    el.innerHTML = SECTIONS.map((skey, idx) => {
        const text = entry[skey] || '(no content)';
        const v = validate(text);
        const review = (reviewNotes[currentCluster]||{})[skey] || {};
        const statusHtml = review.status
            ? `<span class="status-badge status-${review.status}">${review.status}</span>` : '';
        const focusCls = idx === currentSectionIdx ? ' style="border-left:3px solid var(--accent)"' : '';
        return `<div class="section-card" id="section-${idx}"${focusCls}>
            <div class="section-header">
                <span class="section-name">${SECTION_DISPLAY[skey]}</span>
                ${statusHtml}
            </div>
            <div class="section-text">${escHtml(text)}</div>
            <div class="validation">
                ${vtag(v.length_ok, v.word_count + ' words')}
                ${vtag(!v.banned.length, v.banned.length ? 'Banned: ' + v.banned.join(', ') : 'No banned words')}
                ${vtag(!v.hedging.length, v.hedging.length ? 'Hedging: ' + v.hedging.join(', ') : 'No hedging')}
                ${vtag(v.second_person, v.second_person ? '2nd person ✓' : 'Missing 2nd person')}
                ${vtag(v.declarative, v.declarative ? 'Declarative ✓' : 'Ends with ?')}
                ${v.american.length ? `<span class="val-tag warn">US spelling: ${v.american.join(', ')}</span>` : ''}
            </div>
            <div class="controls">
                <button class="btn btn-approve" onclick="setStatus('${skey}','approved')">Approve (a)</button>
                <button class="btn btn-revise" onclick="setStatus('${skey}','needs_revision')">Revise (r)</button>
                <button class="btn btn-reject" onclick="setStatus('${skey}','rejected')">Reject (x)</button>
                <input class="note-input" id="note-${skey}" placeholder="Reviewer note..."
                    value="${escAttr(review.note||'')}" onchange="saveNote('${skey}',this.value)">
            </div>
        </div>`;
    }).join('');
}

function validate(text) {
    const words = text.split(/\\s+/).filter(w=>w);
    const lower = text.toLowerCase();
    const banned = {{ banned | tojson }}.filter(w => lower.includes(w));
    if (lower.includes('landscape')) banned.push('landscape');
    const hedging = {{ hedging | tojson }}.filter(p => lower.includes(p));
    const sp = ['You','Your','you','your'].some(m => text.includes(m));
    const decl = !text.trim().endsWith('?');
    const american = [];
    for (const [us,uk] of Object.entries({{ american | tojson }})) {
        if (lower.includes(us)) american.push(us+'→'+uk);
    }
    return {word_count:words.length, length_ok:words.length>=50&&words.length<=150,
        banned, hedging, second_person:sp, declarative:decl, american};
}

function vtag(ok, label) {
    return `<span class="val-tag ${ok?'pass':'fail'}">${label}</span>`;
}

async function setStatus(skey, status) {
    if (!reviewNotes[currentCluster]) reviewNotes[currentCluster] = {};
    const note = document.getElementById('note-'+skey)?.value || '';
    reviewNotes[currentCluster][skey] = {
        status, note, reviewed_at: new Date().toISOString()
    };
    await fetch('/api/review', {
        method: 'POST',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify({cluster: currentCluster, section: skey, status, note})
    });
    renderSections();
    renderClusterList();
    updateStats();
}

async function saveNote(skey, note) {
    if (!reviewNotes[currentCluster]) reviewNotes[currentCluster] = {};
    if (!reviewNotes[currentCluster][skey]) reviewNotes[currentCluster][skey] = {status: '', note: '', reviewed_at: ''};
    reviewNotes[currentCluster][skey].note = note;
    await fetch('/api/review', {
        method: 'POST',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify({
            cluster: currentCluster, section: skey,
            status: reviewNotes[currentCluster][skey].status, note
        })
    });
}

async function togglePause() {
    paused = !paused;
    await fetch('/api/pause', {
        method: 'POST',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify({paused})
    });
    updatePauseBtn();
}

function updatePauseBtn() {
    const btn = document.getElementById('pause-btn');
    btn.textContent = paused ? 'Resume Pipeline' : 'Pause Pipeline';
    btn.className = paused ? 'btn btn-resume' : 'btn btn-pause';
}

function updateStats() {
    let total=0, approved=0, revision=0, rejected=0;
    for (const ck of clusters) {
        for (const sk of SECTIONS) {
            total++;
            const s = (reviewNotes[ck]||{})[sk]?.status;
            if (s==='approved') approved++;
            else if (s==='needs_revision') revision++;
            else if (s==='rejected') rejected++;
        }
    }
    document.getElementById('stat-total').textContent = total;
    document.getElementById('stat-approved').textContent = approved;
    document.getElementById('stat-revision').textContent = revision;
    document.getElementById('stat-rejected').textContent = rejected;
    document.getElementById('stat-unreviewed').textContent = total-approved-revision-rejected;
}

function escHtml(s) { return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
function escAttr(s) { return s.replace(/"/g,'&quot;'); }

document.addEventListener('keydown', e => {
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;
    const skey = SECTIONS[currentSectionIdx];
    if (e.key === 'a') setStatus(skey, 'approved');
    else if (e.key === 'r') setStatus(skey, 'needs_revision');
    else if (e.key === 'x') setStatus(skey, 'rejected');
    else if (e.key === 'j' || e.key === 'ArrowDown') {
        if (currentSectionIdx < SECTIONS.length-1) {
            currentSectionIdx++;
            document.getElementById('section-'+currentSectionIdx)?.scrollIntoView({behavior:'smooth',block:'center'});
            renderSections();
        }
    } else if (e.key === 'k' || e.key === 'ArrowUp') {
        if (currentSectionIdx > 0) {
            currentSectionIdx--;
            document.getElementById('section-'+currentSectionIdx)?.scrollIntoView({behavior:'smooth',block:'center'});
            renderSections();
        }
    } else if (e.key === ']') {
        const idx = clusters.indexOf(currentCluster);
        if (idx < clusters.length-1) selectCluster(clusters[idx+1]);
    } else if (e.key === '[') {
        const idx = clusters.indexOf(currentCluster);
        if (idx > 0) selectCluster(clusters[idx-1]);
    }
});

init();
</script>
</body>
</html>"""


# ─── Flask Routes ──────────────────────────────────────────────────────

@app.route("/")
def index():
    return render_template_string(
        TEMPLATE,
        sections=SECTION_KEYS,
        display=SECTION_DISPLAY,
        banned=BANNED_WORDS,
        hedging=HEDGING_PHRASES,
        american=AMERICAN_SPELLINGS,
    )


@app.route("/api/data")
def api_data():
    return jsonify({
        "cache": load_cache(),
        "review_notes": load_review_notes(),
        "paused": is_paused(),
    })


@app.route("/api/review", methods=["POST"])
def api_review():
    data = request.json
    notes = load_review_notes()
    cluster = data["cluster"]
    section = data["section"]

    if cluster not in notes:
        notes[cluster] = {}

    notes[cluster][section] = {
        "status": data["status"],
        "note": data.get("note", ""),
        "reviewed_at": datetime.now(timezone.utc).isoformat(),
    }

    save_review_notes(notes)
    return jsonify({"ok": True})


@app.route("/api/pause", methods=["POST"])
def api_pause():
    data = request.json
    if data.get("paused"):
        with open(PAUSE_PATH, "w") as f:
            json.dump({
                "paused": True,
                "paused_at": datetime.now(timezone.utc).isoformat(),
                "reason": "manual halt",
            }, f, indent=2)
    else:
        if os.path.exists(PAUSE_PATH):
            os.remove(PAUSE_PATH)
    return jsonify({"ok": True})


# ─── Main ──────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Cosmic Fit Narrative Review Tool")
    parser.add_argument("--cache", default="blueprint_narrative_cache.json")
    parser.add_argument("--port", type=int, default=8420)
    args = parser.parse_args()

    CACHE_PATH = args.cache
    review_dir = os.path.dirname(os.path.abspath(args.cache))
    REVIEW_PATH = os.path.join(review_dir, "review_notes.json")
    PAUSE_PATH = os.path.join(review_dir, "pause_signal.json")

    print(f"Narrative Review Tool — http://localhost:{args.port}")
    print(f"Cache: {CACHE_PATH}")
    print(f"Review notes: {REVIEW_PATH}")
    app.run(host="localhost", port=args.port, debug=False)
