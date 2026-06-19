#!/usr/bin/env python3
"""
Cosmic Fit — Content Audit Tool (Web UI)

Flask web interface for reviewing content audit results, triaging issues,
and exporting handoff packs. Modelled on tools/review_tool.py.

Usage (from repo root):
    python3 tools/content_audit_tool.py [--port 8422]
"""

import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

try:
    from flask import Flask, render_template_string, request, jsonify, send_file
except ImportError:
    print("ERROR: Flask not installed. Install with: pip install -r tools/requirements.txt")
    sys.exit(1)


REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "tools"))
from content_audit import build_handoff_pack  # noqa: E402

DATA_DIR = REPO_ROOT / "data" / "style_guide"
REPORT_PATH = DATA_DIR / "audit_report.json"
PROGRESS_PATH = DATA_DIR / "audit_progress.json"
NOTES_PATH = DATA_DIR / "audit_review_notes.json"
PAUSE_PATH = DATA_DIR / "audit_pause_signal.json"
HANDOFF_PATH = DATA_DIR / "audit_handoff_pack.json"
HANDOFF_FINAL_PATH = DATA_DIR / "audit_handoff_final.json"
MARKDOWN_PATH = DATA_DIR / "audit_report.md"
APPLY_LOG_PATH = DATA_DIR / "audit_apply_log.json"

app = Flask(__name__)
_audit_process = None


def is_paused() -> bool:
    if not PAUSE_PATH.exists():
        return False
    try:
        return json.loads(PAUSE_PATH.read_text()).get("paused", False)
    except Exception:
        return False


def set_paused(paused: bool):
    if paused:
        PAUSE_PATH.write_text(json.dumps({
            "paused": True,
            "paused_at": datetime.now(timezone.utc).isoformat(),
            "reason": "manual halt",
        }, indent=2))
    elif PAUSE_PATH.exists():
        PAUSE_PATH.unlink()


def load_report() -> dict:
    if not REPORT_PATH.exists():
        return {"meta": {}, "items": [], "issues": []}
    try:
        return json.loads(REPORT_PATH.read_text())
    except Exception:
        return {"meta": {}, "items": [], "issues": []}


def load_progress() -> dict:
    if not PROGRESS_PATH.exists():
        return {"total": 0, "completed": 0, "percent": 0, "issues_found": 0, "current_item": ""}
    try:
        return json.loads(PROGRESS_PATH.read_text())
    except Exception:
        return {"total": 0, "completed": 0, "percent": 0, "issues_found": 0, "current_item": ""}


def load_notes() -> dict:
    if not NOTES_PATH.exists():
        return {}
    try:
        return json.loads(NOTES_PATH.read_text())
    except Exception:
        return {}


def save_notes(notes: dict):
    NOTES_PATH.write_text(json.dumps(notes, indent=2, ensure_ascii=False))


def load_apply_log() -> dict:
    """Load correction pipeline log keyed by json_edit_path."""
    empty = {"meta": {}, "by_path": {}}
    if not APPLY_LOG_PATH.exists():
        return empty
    try:
        data = json.loads(APPLY_LOG_PATH.read_text(encoding="utf-8"))
    except Exception:
        return empty

    by_path: dict[str, dict] = {}
    for entry in data.get("entries", []):
        path = entry.get("json_edit_path")
        if path:
            by_path[path] = entry

    rewrite_applied = sum(1 for e in by_path.values() if e.get("rewrite_status") == "applied")
    rewrite_failed = sum(1 for e in by_path.values() if e.get("rewrite_status") == "failed")
    rewrite_skipped = sum(1 for e in by_path.values() if e.get("rewrite_status") == "skipped")
    mechanical_applied = sum(1 for e in by_path.values() if e.get("mechanical_status") == "applied")

    return {
        "meta": {
            "generated_at": data.get("generated_at", ""),
            "total_entries": len(by_path),
            "rewrite_applied": rewrite_applied,
            "rewrite_failed": rewrite_failed,
            "rewrite_skipped": rewrite_skipped,
            "mechanical_applied": mechanical_applied,
        },
        "by_path": by_path,
    }


TEMPLATE = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Cosmic Fit — Content Audit</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=DM+Serif+Text&family=PT+Serif:wght@400;700&display=swap" rel="stylesheet">
<style>
:root {
    --bg: #DEDEDE; --surface: #fff; --card: #f4f4f5;
    --accent: #0D0E1F; --accent-lilac: #7E69E6;
    --text: #000210; --dim: #6A6A73; --border: rgba(0,2,16,0.12);
    --green: #2e7d32; --yellow: #e6a100; --red: #c62828; --blue: #1565c0;
    --critical-bg: rgba(198,40,40,0.08); --high-bg: rgba(230,161,0,0.08);
    --medium-bg: rgba(21,101,192,0.08); --low-bg: rgba(0,0,0,0.04);
}
* { box-sizing: border-box; margin: 0; padding: 0; }
body { background: var(--bg); color: var(--text); font: 14px/1.6 'PT Serif', Georgia, serif; display: flex; height: 100vh; }

.sidebar { width: 300px; background: var(--surface); overflow-y: auto; flex-shrink: 0; border-right: 1px solid var(--border); display: flex; flex-direction: column; }
.sidebar-header { padding: 16px; border-bottom: 1px solid var(--border); }
.sidebar-header h1 { font-family: 'DM Serif Text', Georgia, serif; font-size: 18px; color: var(--accent); }
.sidebar-header h2 { font-size: 13px; font-family: 'DM Serif Text', Georgia, serif; color: var(--dim); }
.sidebar-filters { padding: 8px 16px; border-bottom: 1px solid var(--border); display: flex; flex-wrap: wrap; gap: 4px; }
.filter-btn { font-size: 11px; padding: 2px 8px; border-radius: 4px; border: 1px solid var(--border); background: var(--card); cursor: pointer; font-family: 'PT Serif', Georgia, serif; }
.filter-btn.active { background: var(--accent); color: #fff; border-color: var(--accent); }
.sidebar-items { flex: 1; overflow-y: auto; }
.sidebar-item { padding: 8px 16px; cursor: pointer; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; font-size: 12px; transition: background 0.15s; }
.sidebar-item:hover { background: var(--card); }
.sidebar-item.active { background: var(--card); border-left: 3px solid var(--accent); }
.sidebar-item.has-issues { }
.badge { font-size: 10px; padding: 1px 6px; border-radius: 8px; font-weight: 600; }
.badge-critical { background: var(--red); color: #fff; }
.badge-high { background: var(--yellow); color: #fff; }
.badge-medium { background: var(--blue); color: #fff; }
.badge-low { background: var(--bg); color: var(--dim); }
.badge-none { background: var(--green); color: #fff; }
.triage-badge { font-size: 9px; padding: 1px 5px; border-radius: 3px; margin-left: 4px; }
.triage-needs_fix { background: var(--red); color: #fff; }
.triage-false_positive { background: var(--dim); color: #fff; }
.triage-acknowledged { background: var(--blue); color: #fff; }
.triage-fixed { background: var(--green); color: #fff; }
.amend-badge { font-size: 10px; padding: 2px 8px; border-radius: 4px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.03em; }
.amend-applied { background: var(--green); color: #fff; }
.amend-mechanical { background: #558b2f; color: #fff; }
.amend-failed { background: var(--red); color: #fff; }
.amend-skipped { background: var(--dim); color: #fff; }
.amendment-card { background: rgba(126,105,230,0.06); border: 1px solid rgba(126,105,230,0.25); border-radius: 8px; padding: 14px; margin-bottom: 14px; }
.amendment-header { display: flex; flex-wrap: wrap; gap: 8px; align-items: center; margin-bottom: 10px; }
.amend-time { font-size: 11px; color: var(--dim); margin-left: auto; }
.amend-diff { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
@media (max-width: 900px) { .amend-diff { grid-template-columns: 1fr; } }
.amend-before, .amend-after { padding: 10px; border-radius: 6px; font-size: 12px; line-height: 1.6; white-space: pre-wrap; word-break: break-word; }
.amend-before { background: rgba(198,40,40,0.06); border: 1px solid rgba(198,40,40,0.2); }
.amend-after { background: rgba(46,125,50,0.08); border: 1px solid rgba(46,125,50,0.25); }
.amend-label { font-size: 10px; text-transform: uppercase; letter-spacing: 0.04em; color: var(--dim); margin-bottom: 6px; font-weight: 700; }
.amend-reason { font-size: 12px; color: var(--dim); font-style: italic; }
.stale-banner { background: rgba(230,161,0,0.12); border: 1px solid rgba(230,161,0,0.35); color: #8a6500; padding: 10px 14px; border-radius: 6px; margin-bottom: 16px; font-size: 12px; }
.sidebar-amend { font-size: 9px; padding: 1px 5px; border-radius: 3px; margin-left: 4px; font-weight: 700; }
.sidebar-amend-applied { background: var(--green); color: #fff; }
.sidebar-amend-failed { background: var(--red); color: #fff; }
.sidebar-amend-skipped { background: var(--dim); color: #fff; }
.card-section-label { font-size: 11px; text-transform: uppercase; letter-spacing: 0.04em; color: var(--dim); margin-bottom: 6px; font-weight: 700; }

.main { flex: 1; overflow-y: auto; padding: 24px; }
.top-bar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 24px; padding: 16px; background: var(--surface); border-radius: 8px; border: 1px solid var(--border); flex-wrap: wrap; gap: 12px; }
.stats { display: flex; gap: 20px; font-size: 13px; flex-wrap: wrap; }
.stat-label { color: var(--dim); font-size: 10px; text-transform: uppercase; letter-spacing: 0.04em; }
.stat-value { font-weight: 700; font-size: 16px; font-family: 'DM Serif Text', Georgia, serif; }
.top-actions { display: flex; gap: 8px; flex-wrap: wrap; }

.progress-bar { width: 100%; height: 4px; background: var(--border); border-radius: 2px; margin-bottom: 20px; overflow: hidden; }
.progress-fill { height: 100%; background: var(--accent-lilac); transition: width 0.3s; border-radius: 2px; }

.content-card { background: var(--surface); border-radius: 8px; padding: 20px; margin-bottom: 16px; border: 1px solid var(--border); }
.content-card.active-card { border-color: var(--accent-lilac); box-shadow: 0 0 0 2px rgba(126,105,230,0.15); }
.card-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; flex-wrap: wrap; gap: 8px; }
.card-source { font-size: 11px; color: var(--dim); }
.card-section { font-size: 14px; font-weight: 600; font-family: 'DM Serif Text', Georgia, serif; }
.card-text { padding: 12px; background: var(--card); border-radius: 6px; font-size: 13px; line-height: 1.7; white-space: pre-wrap; margin-bottom: 12px; border: 1px solid var(--border); word-break: break-word; }
.highlight-critical { background: rgba(198,40,40,0.15); border-radius: 2px; }
.highlight-high { background: rgba(230,161,0,0.15); border-radius: 2px; }
.highlight-medium { background: rgba(21,101,192,0.12); border-radius: 2px; }
.highlight-low { background: rgba(0,0,0,0.06); border-radius: 2px; }

.issue-list { margin-bottom: 12px; }
.issue-item { padding: 8px 12px; border-radius: 6px; margin-bottom: 6px; font-size: 12px; line-height: 1.5; }
.issue-item.critical { background: var(--critical-bg); border-left: 3px solid var(--red); }
.issue-item.high { background: var(--high-bg); border-left: 3px solid var(--yellow); }
.issue-item.medium { background: var(--medium-bg); border-left: 3px solid var(--blue); }
.issue-item.low { background: var(--low-bg); border-left: 3px solid var(--dim); }
.issue-check { font-weight: 700; font-size: 11px; text-transform: uppercase; }
.issue-why { margin-top: 2px; }
.issue-fix { margin-top: 4px; color: var(--dim); font-style: italic; }

.controls { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
.btn { padding: 6px 16px; border: none; border-radius: 6px; cursor: pointer; font-size: 12px; font-weight: 600; font-family: 'PT Serif', Georgia, serif; transition: opacity 0.15s; }
.btn:hover { opacity: 0.85; }
.btn-primary { background: var(--accent); color: #fff; }
.btn-needs-fix { background: var(--red); color: #fff; }
.btn-false-positive { background: var(--dim); color: #fff; }
.btn-acknowledged { background: var(--blue); color: #fff; }
.btn-fixed { background: var(--green); color: #fff; }
.btn-export { background: var(--accent-lilac); color: #fff; }
.btn-pause { background: var(--accent); color: #fff; }
.btn-resume { background: var(--green); color: #fff; }
.note-input { flex: 1; padding: 6px 10px; border: 1px solid var(--border); border-radius: 6px; background: var(--card); color: var(--text); font-size: 12px; font-family: 'PT Serif', Georgia, serif; min-width: 200px; }
.note-input:focus { outline: none; border-color: var(--accent-lilac); box-shadow: 0 0 0 2px rgba(126,105,230,0.2); }

.no-issues { text-align: center; padding: 40px; color: var(--dim); font-size: 16px; font-family: 'DM Serif Text', Georgia, serif; }

.keyboard-help { position: fixed; bottom: 12px; right: 12px; font-size: 11px; color: var(--dim); background: var(--surface); padding: 8px 12px; border-radius: 6px; border: 1px solid var(--border); z-index: 10; }
kbd { background: var(--bg); padding: 1px 6px; border-radius: 3px; font-size: 11px; border: 1px solid var(--border); }
</style>
</head>
<body>

<div class="sidebar">
    <div class="sidebar-header">
        <h1>Cosmic Fit</h1>
        <h2>Content Audit Tool</h2>
    </div>
    <div class="sidebar-filters" id="sidebar-filters"></div>
    <div class="sidebar-items" id="sidebar-items"></div>
</div>

<div class="main">
    <div class="top-bar">
        <div class="stats">
            <div><div class="stat-label">Items</div><div class="stat-value" id="stat-items">0</div></div>
            <div><div class="stat-label">Flagged</div><div class="stat-value" id="stat-flagged" style="color:var(--red)">0</div></div>
            <div><div class="stat-label">Issues</div><div class="stat-value" id="stat-issues">0</div></div>
            <div><div class="stat-label" style="color:var(--red)">Critical</div><div class="stat-value" id="stat-critical" style="color:var(--red)">0</div></div>
            <div><div class="stat-label" style="color:var(--yellow)">High</div><div class="stat-value" id="stat-high" style="color:var(--yellow)">0</div></div>
            <div><div class="stat-label" style="color:var(--blue)">Medium</div><div class="stat-value" id="stat-medium" style="color:var(--blue)">0</div></div>
            <div><div class="stat-label">Low</div><div class="stat-value" id="stat-low">0</div></div>
            <div><div class="stat-label">Triaged</div><div class="stat-value" id="stat-triaged" style="color:var(--green)">0</div></div>
            <div><div class="stat-label">Amended</div><div class="stat-value" id="stat-amended" style="color:var(--green)">0</div></div>
            <div><div class="stat-label">Amend failed</div><div class="stat-value" id="stat-amend-failed" style="color:var(--red)">0</div></div>
        </div>
        <div class="top-actions">
            <button class="btn btn-primary" id="run-btn" onclick="runAudit()">Run Audit</button>
            <button class="btn btn-pause" id="pause-btn" onclick="togglePause()">Pause Audit</button>
            <button class="btn btn-export" onclick="exportReport('json')">Export JSON</button>
            <button class="btn btn-export" onclick="exportReport('markdown')">Export Markdown</button>
            <button class="btn btn-export" onclick="exportReport('handoff')">Export Handoff</button>
            <button class="btn btn-export" onclick="exportReport('handoff_final')">Export Final Handoff</button>
        </div>
    </div>
    <div class="progress-bar" id="progress-bar" style="display:none"><div class="progress-fill" id="progress-fill"></div></div>
    <div id="content-area"></div>
</div>

<div class="keyboard-help">
    <kbd>j</kbd>/<kbd>&#x2193;</kbd> next &nbsp; <kbd>k</kbd>/<kbd>&#x2191;</kbd> prev &nbsp;
    <kbd>]</kbd> next group &nbsp; <kbd>[</kbd> prev group &nbsp;
    <kbd>1</kbd>-<kbd>4</kbd> filter priority &nbsp;
    <kbd>f</kbd> flagged only &nbsp; <kbd>n</kbd> needs fix &nbsp;
    <kbd>p</kbd> false positive &nbsp; <kbd>a</kbd> acknowledged
</div>

<script>
let report = {meta:{}, items:[], issues:[]};
let notes = {};
let amendments = {meta:{}, by_path:{}};
let progress = {};
let filteredItems = [];
let currentIdx = 0;
let activeFilter = 'all';
let flaggedOnly = false;
let paused = false;
let auditRunning = false;
let lastProgressPct = -1;

const PRIORITY_ORDER = {critical:0, high:1, medium:2, low:3, none:4};

async function init() {
    await loadData();
    renderFilters();
    applyFilter();
    renderStats();
    updatePauseBtn();
    setInterval(pollProgress, 2000);
}

async function loadData() {
    try {
        const [rRes, nRes, aRes] = await Promise.all([
            fetch('/api/report'),
            fetch('/api/notes'),
            fetch('/api/amendments'),
        ]);
        report = await rRes.json();
        notes = await nRes.json();
        amendments = await aRes.json();
    } catch(e) {}
}

function getAmendment(item) {
    return amendments.by_path?.[item.json_edit_path] || null;
}

function isReportStale() {
    const reportAt = report.meta?.generated_at || '';
    const amendAt = amendments.meta?.generated_at || '';
    return Boolean(reportAt && amendAt && amendAt > reportAt);
}

function amendmentStatusLabel(amendment) {
    if (!amendment) return null;
    if (amendment.rewrite_status === 'applied') return {label: 'Rewrite applied', cls: 'amend-applied'};
    if (amendment.rewrite_status === 'failed') return {label: 'Rewrite failed', cls: 'amend-failed'};
    if (amendment.rewrite_status === 'skipped') return {label: 'Rewrite skipped', cls: 'amend-skipped'};
    if (amendment.mechanical_status === 'applied') return {label: 'Mechanical fix', cls: 'amend-mechanical'};
    return null;
}

function hasSuccessfulAmendment(amendment) {
    if (!amendment) return false;
    if (amendment.rewrite_status === 'applied') return true;
    return amendment.mechanical_status === 'applied' && Boolean(amendment.old_value && amendment.new_value);
}

function renderAmendmentPanel(item, amendment) {
    if (!amendment) return '';
    const status = amendmentStatusLabel(amendment);
    if (!status) return '';

    const handoffPrio = amendment.priority || '';
    const oldVal = amendment.old_value || '';
    const newVal = amendment.new_value || '';
    const reason = amendment.reason || '';
    const ts = (amendment.timestamp || '').replace('T', ' ').slice(0, 19);

    let body = '';
    if (oldVal && newVal && oldVal !== newVal) {
        body = `<div class="amend-diff">
            <div class="amend-before"><div class="amend-label">Before (pre-correction)</div>${escHtml(oldVal)}</div>
            <div class="amend-after"><div class="amend-label">After (applied)</div>${escHtml(newVal)}</div>
        </div>`;
    } else if (reason) {
        body = `<div class="amend-reason">${escHtml(reason)}</div>`;
    }

    const auditText = item.original_content || '';
    const matchesAfter = newVal && auditText === newVal;
    const matchNote = newVal
        ? (matchesAfter
            ? '<div class="amend-reason" style="color:var(--green);font-style:normal;margin-top:8px">Current audit text matches the applied correction.</div>'
            : '<div class="amend-reason" style="margin-top:8px">Current audit text differs from applied correction — run <strong>Run Audit</strong> to refresh, or this item was not re-scanned yet.</div>')
        : '';

    return `<div class="amendment-card">
        <div class="amendment-header">
            <span class="amend-badge ${status.cls}">${status.label}</span>
            ${handoffPrio ? `<span class="badge badge-${handoffPrio}">Handoff: ${handoffPrio.toUpperCase()}</span>` : ''}
            ${ts ? `<span class="amend-time">${escHtml(ts)} UTC</span>` : ''}
        </div>
        ${body}
        ${matchNote}
    </div>`;
}

function sidebarAmendBadge(amendment) {
    if (!amendment) return '';
    if (amendment.rewrite_status === 'applied' || amendment.mechanical_status === 'applied') {
        return '<span class="sidebar-amend sidebar-amend-applied">✓</span>';
    }
    if (amendment.rewrite_status === 'failed') {
        return '<span class="sidebar-amend sidebar-amend-failed">✗</span>';
    }
    if (amendment.rewrite_status === 'skipped') {
        return '<span class="sidebar-amend sidebar-amend-skipped">–</span>';
    }
    return '';
}

function getItemIssues(contentId) {
    return report.issues.filter(i => i.content_id === contentId);
}

function getHighestPriority(issues) {
    let best = 'none';
    for (const i of issues) {
        if (PRIORITY_ORDER[i.priority] < PRIORITY_ORDER[best]) best = i.priority;
    }
    return best;
}

function renderFilters() {
    const el = document.getElementById('sidebar-filters');
    const filters = ['all','critical','high','medium','low','amended'];
    el.innerHTML = filters.map(f =>
        `<button class="filter-btn${activeFilter===f?' active':''}" onclick="setFilter('${f}')">${f}</button>`
    ).join('') + `<button class="filter-btn${flaggedOnly?' active':''}" onclick="toggleFlagged()">flagged</button>`;
}

function setFilter(f) {
    activeFilter = f;
    applyFilter();
    renderFilters();
}

function toggleFlagged() {
    flaggedOnly = !flaggedOnly;
    applyFilter();
    renderFilters();
}

function applyFilter() {
    let items = report.items || [];
    if (flaggedOnly) {
        items = items.filter(it => it.issue_count > 0);
    }
    if (activeFilter === 'amended') {
        items = items.filter(it => hasSuccessfulAmendment(getAmendment(it)));
    } else if (activeFilter !== 'all') {
        items = items.filter(it => it.highest_priority === activeFilter);
    }
    items.sort((a,b) => (PRIORITY_ORDER[a.highest_priority]||4) - (PRIORITY_ORDER[b.highest_priority]||4));
    filteredItems = items;
    currentIdx = Math.min(currentIdx, Math.max(0, filteredItems.length - 1));
    renderSidebar();
    renderContent();
}

function renderSidebar() {
    const el = document.getElementById('sidebar-items');
    el.innerHTML = filteredItems.map((item, idx) => {
        const cls = idx === currentIdx ? ' active' : '';
        const prio = item.highest_priority || 'none';
        const note = notes[item.content_id];
        const triageBadge = note?.status ? `<span class="triage-badge triage-${note.status}">${note.status}</span>` : '';
        const amendBadge = sidebarAmendBadge(getAmendment(item));
        const label = item.content_id.length > 40 ? '...' + item.content_id.slice(-37) : item.content_id;
        return `<div class="sidebar-item${cls}" onclick="selectItem(${idx})" title="${escAttr(item.content_id)}">
            <span style="flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${escHtml(label)}</span>
            <span><span class="badge badge-${prio}">${item.issue_count}</span>${amendBadge}${triageBadge}</span>
        </div>`;
    }).join('');
}

function selectItem(idx) {
    currentIdx = idx;
    renderSidebar();
    renderContent();
    document.getElementById('card-' + idx)?.scrollIntoView({behavior:'smooth', block:'center'});
}

function highlightText(text, issues) {
    let html = escHtml(text || '');
    const frags = issues
        .filter(i => i.flagged_fragment && i.flagged_fragment.length > 2)
        .sort((a, b) => (b.flagged_fragment.length || 0) - (a.flagged_fragment.length || 0));
    for (const iss of frags) {
        const frag = escHtml(iss.flagged_fragment);
        if (frag && html.includes(frag)) {
            html = html.replace(frag, `<span class="highlight-${iss.priority}">${frag}</span>`);
        }
    }
    return html;
}

function renderContent() {
    const el = document.getElementById('content-area');
    if (!filteredItems.length) {
        el.innerHTML = '<div class="no-issues">No items match the current filter.</div>';
        return;
    }
    const item = filteredItems[currentIdx];
    if (!item) { el.innerHTML = ''; return; }
    const issues = getItemIssues(item.content_id);
    const note = notes[item.content_id] || {};
    const activeCls = ' active-card';

    const amendment = getAmendment(item);
    const staleBanner = isReportStale()
        ? '<div class="stale-banner">Audit report is older than the last correction run. Click <strong>Run Audit</strong> to refresh current text and issue counts.</div>'
        : '';
    let textHtml = highlightText(item.original_content || '', issues);
    const currentLabel = isReportStale()
        ? 'Current text (audit snapshot — may be stale)'
        : 'Current text (from latest audit scan)';
    el.innerHTML = `${staleBanner}<div class="content-card${activeCls}" id="card-${currentIdx}">
        <div class="card-header">
            <div>
                <div class="card-section">${escHtml(item.ui_section || '')}</div>
                <div class="card-source">${escHtml(item.source_layer || '')} &middot; ${escHtml(item.source_file || '')} &middot; <code>${escHtml(item.json_edit_path || '')}</code></div>
            </div>
            <span class="badge badge-${item.highest_priority || 'none'}">${(item.highest_priority||'none').toUpperCase()}</span>
        </div>
        ${renderAmendmentPanel(item, amendment)}
        <div class="card-section-label">${currentLabel}</div>
        <div class="card-text">${textHtml}</div>
        ${issues.length ? '<div class="issue-list">' + issues.map(iss => `
            <div class="issue-item ${iss.priority}">
                <div><span class="issue-check">${escHtml(iss.check_id)}</span> <span class="badge badge-${iss.priority}">${iss.priority}</span></div>
                <div class="issue-why">${escHtml(iss.why || '')}</div>
                ${iss.flagged_fragment ? `<div class="issue-fix"><strong>Fragment:</strong> "${escHtml(iss.flagged_fragment)}"</div>` : ''}
                ${iss.suggested_fix ? `<div class="issue-fix"><strong>Suggested:</strong> ${escHtml(iss.suggested_fix)}</div>` : ''}
                ${iss.rewrite_brief ? `<div class="issue-fix"><strong>Brief:</strong> ${escHtml(iss.rewrite_brief)}</div>` : ''}
                ${iss.auto_fixable ? '<div class="issue-fix" style="color:var(--green)">Auto-fixable</div>' : ''}
            </div>
        `).join('') + '</div>' : '<div style="color:var(--green);font-size:12px;margin-bottom:12px">No issues found.</div>'}
        <div class="controls">
            <button class="btn btn-needs-fix" onclick="triage('needs_fix')">Needs Fix (n)</button>
            <button class="btn btn-false-positive" onclick="triage('false_positive')">False Positive (p)</button>
            <button class="btn btn-acknowledged" onclick="triage('acknowledged')">Acknowledged (a)</button>
            <button class="btn btn-fixed" onclick="triage('fixed')">Fixed</button>
            <input class="note-input" id="note-input" placeholder="Reviewer note..."
                value="${escAttr(note.note||'')}" onchange="saveNote(this.value)">
        </div>
        ${note.status ? `<div style="margin-top:8px;font-size:11px;color:var(--dim)">Status: <strong>${note.status}</strong> (${note.reviewed_at||''})</div>` : ''}
    </div>
    <div style="text-align:center;color:var(--dim);font-size:12px;margin-top:8px">
        Item ${currentIdx+1} of ${filteredItems.length}
    </div>`;
}

function renderStats() {
    const meta = report.meta || {};
    const bp = meta.by_priority || {};
    document.getElementById('stat-items').textContent = meta.total_items || (report.items || []).length;
    document.getElementById('stat-flagged').textContent = meta.flagged_items || (report.items || []).filter(i => i.issue_count > 0).length;
    document.getElementById('stat-issues').textContent = meta.total_issues || 0;
    document.getElementById('stat-critical').textContent = bp.critical || 0;
    document.getElementById('stat-high').textContent = bp.high || 0;
    document.getElementById('stat-medium').textContent = bp.medium || 0;
    document.getElementById('stat-low').textContent = bp.low || 0;
    const triaged = Object.keys(notes).filter(k => notes[k]?.status).length;
    document.getElementById('stat-triaged').textContent = triaged;
    const amendMeta = amendments.meta || {};
    document.getElementById('stat-amended').textContent =
        (amendMeta.rewrite_applied || 0) + (amendMeta.mechanical_applied || 0);
    document.getElementById('stat-amend-failed').textContent = amendMeta.rewrite_failed || 0;
}

async function triage(status) {
    const item = filteredItems[currentIdx];
    if (!item) return;
    const note = document.getElementById('note-input')?.value || '';
    notes[item.content_id] = { status, note, reviewed_at: new Date().toISOString() };
    await fetch('/api/triage', {
        method: 'POST',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify({content_id: item.content_id, status, note})
    });
    renderContent();
    renderSidebar();
    renderStats();
}

async function saveNote(note) {
    const item = filteredItems[currentIdx];
    if (!item) return;
    if (!notes[item.content_id]) notes[item.content_id] = {status:'', note:'', reviewed_at:''};
    notes[item.content_id].note = note;
    await fetch('/api/triage', {
        method: 'POST',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify({
            content_id: item.content_id,
            status: notes[item.content_id].status,
            note
        })
    });
}

async function runAudit() {
    const btn = document.getElementById('run-btn');
    btn.textContent = 'Running...';
    btn.disabled = true;
    auditRunning = true;
    lastProgressPct = -1;
    document.getElementById('progress-bar').style.display = 'block';
    await fetch('/api/run-audit', {method:'POST'});
    updatePauseBtn();
    pollProgress();
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
    if (!auditRunning) {
        btn.textContent = 'Pause Audit';
        btn.className = 'btn btn-pause';
        btn.disabled = true;
        return;
    }
    btn.disabled = false;
    btn.textContent = paused ? 'Resume Audit' : 'Pause Audit';
    btn.className = paused ? 'btn btn-resume' : 'btn btn-pause';
}

async function pollProgress() {
    try {
        const [pRes, pauseRes] = await Promise.all([
            fetch('/api/progress'),
            fetch('/api/pause-state')
        ]);
        progress = await pRes.json();
        const pauseData = await pauseRes.json();
        paused = pauseData.paused;
        updatePauseBtn();

        if (progress.total > 0) {
            auditRunning = progress.percent < 100;
            document.getElementById('progress-bar').style.display = 'block';
            document.getElementById('progress-fill').style.width = progress.percent + '%';
            if (progress.percent !== lastProgressPct) {
                lastProgressPct = progress.percent;
                await loadData();
                applyFilter();
                renderStats();
            }
        }
        if (progress.percent >= 100 && progress.total > 0) {
            document.getElementById('progress-bar').style.display = 'none';
            const btn = document.getElementById('run-btn');
            btn.textContent = 'Run Audit';
            btn.disabled = false;
            auditRunning = false;
            updatePauseBtn();
            await loadData();
            applyFilter();
            renderStats();
        }
    } catch(e) {}
}

function exportReport(format) {
    window.open('/api/export?format=' + format, '_blank');
}

function escHtml(s) { return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
function escAttr(s) { return String(s).replace(/"/g,'&quot;'); }

document.addEventListener('keydown', e => {
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;
    if (e.key === 'j' || e.key === 'ArrowDown') {
        if (currentIdx < filteredItems.length - 1) { selectItem(currentIdx + 1); }
    } else if (e.key === 'k' || e.key === 'ArrowUp') {
        if (currentIdx > 0) { selectItem(currentIdx - 1); }
    } else if (e.key === ']') {
        selectItem(Math.min(currentIdx + 10, filteredItems.length - 1));
    } else if (e.key === '[') {
        selectItem(Math.max(currentIdx - 10, 0));
    } else if (e.key === '1') { setFilter('critical'); }
    else if (e.key === '2') { setFilter('high'); }
    else if (e.key === '3') { setFilter('medium'); }
    else if (e.key === '4') { setFilter('low'); }
    else if (e.key === '0') { setFilter('all'); }
    else if (e.key === 'f') { toggleFlagged(); }
    else if (e.key === 'n') { triage('needs_fix'); }
    else if (e.key === 'p') { triage('false_positive'); }
    else if (e.key === 'a') { triage('acknowledged'); }
});

init();
</script>
</body>
</html>"""


# ─── Flask Routes ──────────────────────────────────────────────────────

@app.route("/")
def index():
    return render_template_string(TEMPLATE)


@app.route("/api/report")
def api_report():
    return jsonify(load_report())


@app.route("/api/notes")
def api_notes():
    return jsonify(load_notes())


@app.route("/api/amendments")
def api_amendments():
    return jsonify(load_apply_log())


@app.route("/api/progress")
def api_progress():
    return jsonify(load_progress())


@app.route("/api/triage", methods=["POST"])
def api_triage():
    data = request.json
    notes = load_notes()
    content_id = data["content_id"]
    notes[content_id] = {
        "status": data.get("status", ""),
        "note": data.get("note", ""),
        "reviewed_at": datetime.now(timezone.utc).isoformat(),
    }
    save_notes(notes)
    return jsonify({"ok": True})


@app.route("/api/pause", methods=["POST"])
def api_pause():
    data = request.json or {}
    set_paused(bool(data.get("paused")))
    return jsonify({"ok": True, "paused": is_paused()})


@app.route("/api/pause-state")
def api_pause_state():
    return jsonify({"paused": is_paused()})


@app.route("/api/run-audit", methods=["POST"])
def api_run_audit():
    global _audit_process
    if _audit_process and _audit_process.poll() is None:
        return jsonify({"ok": False, "error": "Audit already running"})

    set_paused(False)

    venv_python = REPO_ROOT / ".venv" / "bin" / "python3"
    python = str(venv_python) if venv_python.exists() else sys.executable
    script = str(REPO_ROOT / "tools" / "content_audit.py")
    _audit_process = subprocess.Popen(
        [python, script, "--format", "all"],
        cwd=str(REPO_ROOT),
    )
    return jsonify({"ok": True, "pid": _audit_process.pid})


@app.route("/api/export")
def api_export():
    fmt = request.args.get("format", "json")
    if fmt == "json" and REPORT_PATH.exists():
        return send_file(str(REPORT_PATH), mimetype="application/json",
                         as_attachment=True, download_name="audit_report.json")
    elif fmt == "markdown" and MARKDOWN_PATH.exists():
        return send_file(str(MARKDOWN_PATH), mimetype="text/markdown",
                         as_attachment=True, download_name="audit_report.md")
    elif fmt == "handoff" and HANDOFF_PATH.exists():
        return send_file(str(HANDOFF_PATH), mimetype="application/json",
                         as_attachment=True, download_name="audit_handoff_pack.json")
    elif fmt == "handoff_final":
        report = load_report()
        if not report.get("issues"):
            return jsonify({"error": "No audit report found. Run the audit first."}), 404
        notes = load_notes()
        pack = build_handoff_pack(report, notes=notes, filtered=True)
        HANDOFF_FINAL_PATH.write_text(
            json.dumps(pack, indent=2, ensure_ascii=False), encoding="utf-8"
        )
        return send_file(
            str(HANDOFF_FINAL_PATH),
            mimetype="application/json",
            as_attachment=True,
            download_name="audit_handoff_final.json",
        )
    return jsonify({"error": f"Report not found for format '{fmt}'. Run the audit first."}), 404


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Cosmic Fit Content Audit Tool (Web UI)")
    parser.add_argument("--port", type=int, default=8422)
    args = parser.parse_args()

    print(f"Content Audit Tool — http://localhost:{args.port}")
    print(f"Report:     {REPORT_PATH}")
    print(f"Notes:      {NOTES_PATH}")
    print(f"Amendments: {APPLY_LOG_PATH}")
    app.run(host="localhost", port=args.port, debug=False)
