#!/usr/bin/env python3
"""
Cosmic Fit — SynthID single-image drop tool

Local web UI for single-image de-SynthID. Settings adapt to image size via
scripts/synthid_profiles.py (large originals: bigger tiles, wider overlap,
50 steps, gentle 0.04/0.05/0.05 ramp — still 3 passes, no resize).

Processing runs in a separate subprocess. Job state is persisted to disk.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path

try:
    from flask import Flask, Response, jsonify, render_template_string, request, send_from_directory
except ImportError:
    print("ERROR: Flask not installed. Run: pip install flask (in scripts/.venv)")
    sys.exit(1)

REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPTS_DIR = REPO_ROOT / "scripts"
sys.path.insert(0, str(SCRIPTS_DIR))
from synthid_profiles import profile_for_image, profile_summary  # noqa: E402

RESOURCES_DIR = REPO_ROOT / "Resources"
WORKER_SCRIPT = Path(__file__).resolve().parent / "synthid_drop_worker.py"

INBOX_DIR = RESOURCES_DIR / "synthid_drop_inbox"
OUTPUT_DIR = RESOURCES_DIR / "synthid_drop_desynthid"
STATE_DIR = RESOURCES_DIR / "synthid_drop_state"
JOB_FILE = STATE_DIR / "job.json"
LOG_FILE = STATE_DIR / "job.log"

SUPPORTED_EXTS = {".png", ".jpg", ".jpeg"}
DEFAULT_PROFILE = "auto"

_worker_proc: subprocess.Popen | None = None

app = Flask(__name__)


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _ensure_dirs() -> None:
    INBOX_DIR.mkdir(parents=True, exist_ok=True)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    STATE_DIR.mkdir(parents=True, exist_ok=True)


def _safe_basename(name: str) -> str | None:
    base = os.path.basename(name)
    if not base or base in (".", "..") or "/" in base or "\\" in base:
        return None
    ext = os.path.splitext(base)[1].lower()
    if ext not in SUPPORTED_EXTS:
        return None
    return base


def _read_job() -> dict | None:
    if not JOB_FILE.is_file():
        return None
    try:
        return json.loads(JOB_FILE.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return None


def _write_job(data: dict) -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    JOB_FILE.write_text(json.dumps(data, indent=2), encoding="utf-8")


def _tail_log(max_lines: int = 40) -> list[str]:
    if not LOG_FILE.is_file():
        return []
    try:
        lines = LOG_FILE.read_text(encoding="utf-8", errors="replace").splitlines()
        return lines[-max_lines:]
    except OSError:
        return []


def _pid_alive(pid: int | None) -> bool:
    if not pid or pid <= 0:
        return False
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False


def _worker_running() -> bool:
    global _worker_proc
    if _worker_proc is not None:
        code = _worker_proc.poll()
        if code is None:
            return True
        _worker_proc = None

    job = _read_job()
    if not job:
        return False
    if job.get("status") in ("done", "error"):
        return False
    if _pid_alive(job.get("worker_pid")):
        return True
    # Stale job file with no live worker
    out = Path(job["output_path"]) if job.get("output_path") else None
    if out and out.is_file():
        job["status"] = "done"
        job["message"] = "Complete (worker finished; server restarted)"
        job["finished_at"] = _utc_now()
        _write_job(job)
    return False


def _spawn_worker(inbox: Path, output: Path, job_id: str) -> None:
    global _worker_proc
    LOG_FILE.write_text("", encoding="utf-8")
    cmd = [
        sys.executable,
        str(WORKER_SCRIPT),
        "--inbox", str(inbox),
        "--output", str(output),
        "--job-file", str(JOB_FILE),
        "--log-file", str(LOG_FILE),
        "--job-id", job_id,
        "--profile", DEFAULT_PROFILE,
    ]
    _worker_proc = subprocess.Popen(
        cmd,
        cwd=str(REPO_ROOT),
        stdout=subprocess.DEVNULL,
        stderr=subprocess.STDOUT,
    )
    job = _read_job() or {}
    job["worker_pid"] = _worker_proc.pid
    _write_job(job)


def _fallback_done_job() -> dict | None:
    """Recover completed state when job.json is missing (e.g. old server run)."""
    outputs = [
        p for p in OUTPUT_DIR.iterdir()
        if p.is_file() and p.suffix.lower() in SUPPORTED_EXTS
    ]
    if not outputs:
        return None
    latest = max(outputs, key=lambda p: p.stat().st_mtime)
    mtime = datetime.fromtimestamp(latest.stat().st_mtime, tz=timezone.utc)
    inbox = INBOX_DIR / latest.name
    return {
        "id": "recovered",
        "status": "done",
        "message": "Complete",
        "basename": latest.name,
        "inbox_basename": latest.name,
        "output_basename": latest.name,
        "inbox_path": str(inbox) if inbox.is_file() else str(INBOX_DIR / latest.name),
        "output_path": str(latest),
        "started_at": None,
        "finished_at": mtime.isoformat(),
        "progress": {"percent": 100},
    }


def _job_response() -> dict:
    job = _read_job()
    if not job:
        job = _fallback_done_job()
    if not job:
        return {"active": False}

    running = _worker_running()
    active = running and job.get("status") not in ("done", "error")

    # Output on disk means done even if status file is stale
    out_path = Path(job["output_path"]) if job.get("output_path") else None
    if out_path and out_path.is_file() and job.get("status") != "error":
        job = {**job, "status": "done", "message": "Complete", "progress": {"percent": 100}}
        active = False

    out = {"active": active, "server_reachable": True, **_job_public(job)}
    out["log_tail"] = _tail_log()
    if active:
        out["hint"] = "Keep this Mac awake. Progress updates every few seconds."
    elif job.get("status") == "done":
        out["hint"] = "Output ready — upload to Google SynthID checker to validate."
    return out


def _job_public(job: dict) -> dict:
    """Strip fields not needed by the browser."""
    return {k: v for k, v in job.items() if k != "error_detail"}


TEMPLATE = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>SynthID Drop Tool</title>
<link rel="icon" href="data:,">
<style>
  :root {
    --bg: #0d0f14; --surface: #161a22; --border: #2a3140;
    --text: #e8ecf4; --muted: #8b95a8; --accent: #6b9fff;
    --ok: #4ade80; --warn: #fbbf24; --err: #f87171;
  }
  * { box-sizing: border-box; }
  body {
    margin: 0; min-height: 100vh;
    font-family: "SF Pro Text", system-ui, sans-serif;
    background: var(--bg); color: var(--text);
    padding: 2rem 1.5rem;
  }
  .wrap { max-width: 720px; margin: 0 auto; }
  h1 { font-size: 1.35rem; font-weight: 600; margin: 0 0 0.35rem; }
  .sub { color: var(--muted); font-size: 0.9rem; margin-bottom: 1.5rem; line-height: 1.5; }
  .config {
    background: var(--surface); border: 1px solid var(--border);
    border-radius: 10px; padding: 1rem 1.15rem;
    font-size: 0.82rem; color: var(--muted); margin-bottom: 1.25rem; line-height: 1.55;
  }
  .config strong { color: var(--text); font-weight: 500; }
  .drop {
    border: 2px dashed var(--border); border-radius: 12px;
    padding: 2.5rem 1.5rem; text-align: center;
    background: var(--surface); cursor: pointer;
    transition: border-color 0.15s, background 0.15s;
  }
  .drop.dragover { border-color: var(--accent); background: #1a2230; }
  .drop.has-file { border-style: solid; border-color: var(--accent); }
  .drop p { margin: 0.35rem 0; color: var(--muted); font-size: 0.9rem; }
  .drop .fname { color: var(--text); font-weight: 500; margin-top: 0.75rem; }
  input[type=file] { display: none; }
  .actions { margin-top: 1.25rem; display: flex; gap: 0.75rem; flex-wrap: wrap; }
  button {
    background: var(--accent); color: #0d0f14; border: none;
    border-radius: 8px; padding: 0.65rem 1.4rem;
    font-size: 0.95rem; font-weight: 600; cursor: pointer;
  }
  button:disabled { opacity: 0.45; cursor: not-allowed; }
  button.secondary {
    background: transparent; color: var(--muted); border: 1px solid var(--border);
  }
  .status {
    margin-top: 1.25rem; padding: 1rem 1.15rem; border-radius: 10px;
    background: var(--surface); border: 1px solid var(--border);
    font-size: 0.88rem; display: none;
  }
  .status.visible { display: block; }
  .status.processing { border-color: #3d4f6e; }
  .status.done { border-color: #2d5a3e; }
  .status.error { border-color: #5a2d2d; }
  .status .label { font-weight: 600; margin-bottom: 0.35rem; }
  .status.done .label { color: var(--ok); }
  .status.error .label { color: var(--err); }
  .status.processing .label { color: var(--warn); }
  .hint { margin-top: 0.5rem; font-size: 0.8rem; color: var(--muted); }
  .paths { margin-top: 0.75rem; font-size: 0.8rem; color: var(--muted); word-break: break-all; }
  .paths code { color: var(--text); }
  .log {
    margin-top: 0.75rem; max-height: 160px; overflow: auto;
    font-family: ui-monospace, monospace; font-size: 0.72rem;
    color: var(--muted); background: #0a0c10; border-radius: 6px;
    padding: 0.5rem 0.65rem; white-space: pre-wrap;
  }
  .preview { margin-top: 1rem; display: flex; gap: 1rem; flex-wrap: wrap; }
  .preview figure { margin: 0; flex: 1; min-width: 140px; }
  .preview img {
    max-width: 100%; max-height: 220px; border-radius: 8px;
    border: 1px solid var(--border); background: #000;
  }
  .preview figcaption { font-size: 0.75rem; color: var(--muted); margin-top: 0.35rem; }
  .progress-wrap { margin-top: 0.85rem; }
  .progress-bar {
    height: 8px; background: #0a0c10; border-radius: 999px; overflow: hidden;
    border: 1px solid var(--border);
  }
  .progress-fill {
    height: 100%; width: 0%; background: linear-gradient(90deg, #4a7fd4, var(--accent));
    border-radius: 999px; transition: width 0.4s ease;
  }
  .progress-meta { margin-top: 0.4rem; font-size: 0.78rem; color: var(--muted); }
</style>
</head>
<body>
<div class="wrap">
  <h1>SynthID Drop Tool</h1>
  <p class="sub">Run a single image through the proven full-batch de-SynthID settings. Processing runs in a background subprocess — keep the Mac awake.</p>

  <div class="config" id="configBox">
    <strong>Profile</strong> (auto-adaptive from image size):<br>
    <span id="profileSummary">Drop an image to preview settings.</span>
  </div>

  <div class="drop" id="dropZone">
    <p>Drag an image here or click to choose</p>
    <p>PNG, JPG, JPEG</p>
    <p class="fname" id="fileName"></p>
    <input type="file" id="fileInput" accept=".png,.jpg,.jpeg,image/png,image/jpeg">
  </div>

  <div class="actions">
    <button type="button" id="submitBtn" disabled>Submit</button>
    <button type="button" class="secondary" id="clearBtn" disabled>Clear</button>
    <button type="button" class="secondary" id="refreshBtn">Refresh status</button>
  </div>

  <div class="status" id="statusBox">
    <div class="label" id="statusLabel"></div>
    <div id="statusMessage"></div>
    <div class="hint" id="statusHint"></div>
    <div class="progress-wrap" id="progressWrap" hidden>
      <div class="progress-bar"><div class="progress-fill" id="progressFill"></div></div>
      <div class="progress-meta" id="progressMeta"></div>
    </div>
    <div class="paths" id="statusPaths"></div>
    <pre class="log" id="statusLog" hidden></pre>
    <div class="preview" id="preview"></div>
  </div>

  <div class="paths" style="margin-top:2rem">
    Inbox: <code>{{ inbox }}</code><br>
    Output: <code>{{ output }}</code>
  </div>
</div>

<script>
const dropZone = document.getElementById('dropZone');
const fileInput = document.getElementById('fileInput');
const fileName = document.getElementById('fileName');
const submitBtn = document.getElementById('submitBtn');
const clearBtn = document.getElementById('clearBtn');
const refreshBtn = document.getElementById('refreshBtn');
const statusBox = document.getElementById('statusBox');
const statusLabel = document.getElementById('statusLabel');
const statusMessage = document.getElementById('statusMessage');
const statusHint = document.getElementById('statusHint');
const progressWrap = document.getElementById('progressWrap');
const progressFill = document.getElementById('progressFill');
const progressMeta = document.getElementById('progressMeta');
const statusPaths = document.getElementById('statusPaths');
const statusLog = document.getElementById('statusLog');
const preview = document.getElementById('preview');

let selectedFile = null;
let pollTimer = null;
let pollFailures = 0;

function setFile(file) {
  selectedFile = file;
  if (file) {
    dropZone.classList.add('has-file');
    fileName.textContent = file.name;
    submitBtn.disabled = false;
    clearBtn.disabled = false;
    previewProfile(file);
  } else {
    dropZone.classList.remove('has-file');
    fileName.textContent = '';
    submitBtn.disabled = true;
    clearBtn.disabled = true;
    document.getElementById('profileSummary').textContent = 'Drop an image to preview settings.';
  }
}

function previewProfile(file) {
  const el = document.getElementById('profileSummary');
  el.textContent = 'Reading dimensions…';
  const url = URL.createObjectURL(file);
  const img = new Image();
  img.onload = () => {
    URL.revokeObjectURL(url);
    fetch('/api/profile?w=' + img.width + '&h=' + img.height + '&name=' + encodeURIComponent(file.name))
      .then(r => r.json())
      .then(p => {
        el.innerHTML =
          '<code>' + p.name + '</code> · strength ' + p.strength.join(' / ') +
          ' · ' + p.passes + ' passes · ' + p.steps + ' steps · ' +
          p.max_tile + 'px tiles · ' + p.tile_overlap + 'px overlap · ~' +
          p.estimated_total_tile_runs + ' tile runs<br><span style="color:var(--muted)">' +
          p.description + '</span>';
      })
      .catch(() => { el.textContent = 'Could not preview profile.'; });
  };
  img.onerror = () => { URL.revokeObjectURL(url); el.textContent = 'Could not read image.'; };
  img.src = url;
}

dropZone.addEventListener('click', () => fileInput.click());
fileInput.addEventListener('change', () => {
  if (fileInput.files[0]) setFile(fileInput.files[0]);
});

['dragenter','dragover'].forEach(ev => {
  dropZone.addEventListener(ev, e => { e.preventDefault(); dropZone.classList.add('dragover'); });
});
['dragleave','drop'].forEach(ev => {
  dropZone.addEventListener(ev, e => { e.preventDefault(); dropZone.classList.remove('dragover'); });
});
dropZone.addEventListener('drop', e => {
  const f = e.dataTransfer.files[0];
  if (f) setFile(f);
});

clearBtn.addEventListener('click', () => {
  selectedFile = null;
  fileInput.value = '';
  setFile(null);
  stopPoll();
  statusBox.classList.remove('visible','processing','done','error');
  preview.innerHTML = '';
  statusLog.hidden = true;
  progressWrap.hidden = true;
});

function formatElapsed(isoStart) {
  if (!isoStart) return '';
  const ms = Date.now() - new Date(isoStart).getTime();
  if (ms < 0) return '';
  const s = Math.floor(ms / 1000);
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const sec = s % 60;
  if (h > 0) return h + 'h ' + m + 'm elapsed';
  if (m > 0) return m + 'm ' + sec + 's elapsed';
  return sec + 's elapsed';
}

function showStatus(job) {
  statusBox.classList.add('visible');
  statusBox.classList.remove('processing','done','error');
  const labels = {
    queued: 'Queued',
    loading_model: 'Loading model',
    processing: 'Processing',
    done: 'Done',
    error: 'Error',
    busy: 'Busy',
  };
  statusLabel.textContent = labels[job.status] || job.status;
  statusMessage.textContent = job.message || '';
  let hint = job.hint || job.poll_hint || '';
  if (job.profile) {
    const p = job.profile;
    hint += (hint ? ' · ' : '') + 'Profile: ' + p.name + ' (' + p.max_tile + 'px tiles, ' + p.steps + ' steps)';
  }
  statusHint.textContent = hint;

  let paths = '';
  if (job.inbox_path) paths += 'Inbox: <code>' + job.inbox_path + '</code><br>';
  if (job.output_path) paths += 'Output: <code>' + job.output_path + '</code>';
  statusPaths.innerHTML = paths;

  if (job.log_tail && job.log_tail.length) {
    statusLog.hidden = false;
    statusLog.textContent = job.log_tail.join('\n');
    statusLog.scrollTop = statusLog.scrollHeight;
  } else {
    statusLog.hidden = true;
  }

  const pct = job.progress && typeof job.progress.percent === 'number' ? job.progress.percent : null;
  if (job.status === 'processing' || job.status === 'loading_model' || job.status === 'queued') {
    statusBox.classList.add('processing');
    progressWrap.hidden = false;
    progressFill.style.width = (pct != null ? pct : (job.status === 'loading_model' ? 2 : 0)) + '%';
    let meta = '';
    if (job.progress && job.progress.pass) {
      meta = 'Pass ' + job.progress.pass + '/' + job.progress.passes +
             ' · tile ' + job.progress.tile + '/' + job.progress.tiles;
    }
    const elapsed = formatElapsed(job.started_at);
    if (elapsed) meta = meta ? meta + ' · ' + elapsed : elapsed;
    progressMeta.textContent = meta;
  } else if (job.status === 'done') {
    statusBox.classList.add('done');
    progressWrap.hidden = false;
    progressFill.style.width = '100%';
    progressMeta.textContent = job.finished_at
      ? 'Finished ' + new Date(job.finished_at).toLocaleString()
      : 'Complete';
    pollFailures = 0;
    if (job.output_basename) {
      const ts = Date.now();
      preview.innerHTML =
        '<figure><img src="/files/inbox/' + encodeURIComponent(job.inbox_basename) + '?t=' + ts + '" alt="input"><figcaption>Input</figcaption></figure>' +
        '<figure><img src="/files/output/' + encodeURIComponent(job.output_basename) + '?t=' + ts + '" alt="output"><figcaption>De-SynthID output</figcaption></figure>';
    }
  } else if (job.status === 'error') {
    statusBox.classList.add('error');
    progressWrap.hidden = true;
    preview.innerHTML = '';
  } else {
    progressWrap.hidden = true;
  }
}

function stopPoll() {
  if (pollTimer) { clearInterval(pollTimer); pollTimer = null; }
}

function startPoll() {
  stopPoll();
  pollTimer = setInterval(pollJob, 3000);
  pollJob();
}

async function pollJob() {
  try {
    const res = await fetch('/api/job', { cache: 'no-store' });
    const job = await res.json();
    pollFailures = 0;
    showStatus(job);
    if (!job.active) {
      stopPoll();
      submitBtn.disabled = !selectedFile;
    }
  } catch (e) {
    pollFailures++;
    statusBox.classList.add('visible','processing');
    statusLabel.textContent = 'Processing (connection paused)';
    statusMessage.textContent = 'Could not reach server — work may still be running.';
    statusHint.textContent = 'Keep Mac awake. Click Refresh status or reload. (' + pollFailures + ' failed polls)';
    if (pollFailures >= 20) stopPoll();
  }
}

refreshBtn.addEventListener('click', () => pollJob());

submitBtn.addEventListener('click', async () => {
  if (!selectedFile) return;
  submitBtn.disabled = true;
  const fd = new FormData();
  fd.append('file', selectedFile);
  statusBox.classList.add('visible','processing');
  statusLabel.textContent = 'Uploading';
  statusMessage.textContent = 'Sending file…';
  statusHint.textContent = '';
  preview.innerHTML = '';
  statusLog.hidden = true;

  try {
    const res = await fetch('/api/submit', { method: 'POST', body: fd });
    const data = await res.json();
    if (!res.ok) {
      showStatus({ status: 'error', message: data.error || 'Submit failed' });
      submitBtn.disabled = false;
      return;
    }
    showStatus(data);
    startPoll();
  } catch (e) {
    showStatus({ status: 'error', message: 'Upload failed: ' + e.message });
    submitBtn.disabled = false;
  }
});

document.addEventListener('visibilitychange', () => {
  if (!document.hidden && pollTimer) pollJob();
});

fetch('/api/job', { cache: 'no-store' }).then(r => r.json()).then(job => {
  if (job.status) {
    showStatus(job);
    if (job.active) {
      submitBtn.disabled = true;
      startPoll();
    } else if (job.status === 'done') {
      submitBtn.disabled = !selectedFile;
    }
  }
}).catch(() => {});
</script>
</body>
</html>"""


@app.route("/")
def index():
    return render_template_string(
        TEMPLATE,
        inbox=str(INBOX_DIR),
        output=str(OUTPUT_DIR),
    )


@app.route("/api/profile")
def api_profile():
    try:
        w = int(request.args.get("w", 0))
        h = int(request.args.get("h", 0))
    except ValueError:
        return jsonify({"error": "Invalid dimensions"}), 400
    if w <= 0 or h <= 0:
        return jsonify({"error": "width and height required"}), 400
    basename = request.args.get("name", "")
    profile = profile_for_image(w, h, basename=basename or None, profile_name=DEFAULT_PROFILE)
    return jsonify(profile_summary(profile, w, h))


@app.route("/favicon.ico")
def favicon():
    return Response(status=204)


@app.route("/api/job")
def api_job():
    return jsonify(_job_response())


@app.route("/api/log")
def api_log():
    return jsonify({"lines": _tail_log(80)})


@app.route("/api/submit", methods=["POST"])
def api_submit():
    if "file" not in request.files:
        return jsonify({"error": "No file uploaded"}), 400

    upload = request.files["file"]
    if not upload.filename:
        return jsonify({"error": "Empty filename"}), 400

    basename = _safe_basename(upload.filename)
    if not basename:
        return jsonify({"error": "Unsupported file type (use PNG, JPG, or JPEG)"}), 400

    if _worker_running():
        job = _read_job() or {}
        return jsonify({
            "error": "A job is already running",
            "status": "busy",
            "message": f"Processing {job.get('basename', '…')}",
        }), 409

    _ensure_dirs()
    inbox_path = INBOX_DIR / basename
    output_path = OUTPUT_DIR / basename
    upload.save(inbox_path)

    job_id = str(uuid.uuid4())
    job = {
        "id": job_id,
        "status": "queued",
        "message": "Queued — starting worker…",
        "basename": basename,
        "inbox_basename": basename,
        "output_basename": basename,
        "inbox_path": str(inbox_path),
        "output_path": str(output_path),
        "started_at": _utc_now(),
        "profile_name": DEFAULT_PROFILE,
    }
    _write_job(job)
    _spawn_worker(inbox_path, output_path, job_id)

    return jsonify({"active": True, **_job_public(job), "log_tail": []})


@app.route("/files/inbox/<path:filename>")
def serve_inbox(filename: str):
    safe = _safe_basename(filename)
    if not safe:
        return "Not found", 404
    return send_from_directory(INBOX_DIR, safe)


@app.route("/files/output/<path:filename>")
def serve_output(filename: str):
    safe = _safe_basename(filename)
    if not safe:
        return "Not found", 404
    path = OUTPUT_DIR / safe
    if not path.is_file():
        return "Not found", 404
    return send_from_directory(OUTPUT_DIR, safe)


if __name__ == "__main__":
    import argparse
    import logging

    class _QuietPollFilter(logging.Filter):
        def filter(self, record: logging.LogRecord) -> bool:
            msg = record.getMessage()
            return " /api/job " not in msg and " /api/log " not in msg

    logging.getLogger("werkzeug").addFilter(_QuietPollFilter())

    parser = argparse.ArgumentParser(description="Cosmic Fit SynthID single-image drop tool")
    parser.add_argument("--port", type=int, default=8421)
    parser.add_argument("--host", default="127.0.0.1")
    args = parser.parse_args()

    _ensure_dirs()

    print("SynthID Drop Tool")
    print(f"  URL:     http://{args.host}:{args.port}/")
    print(f"  Profile: {DEFAULT_PROFILE} (see scripts/synthid_profiles.py)")
    print(f"  Inbox:   {INBOX_DIR}")
    print(f"  Output:  {OUTPUT_DIR}")
    print(f"  State:   {STATE_DIR}")
    print("  Run from scripts/.venv (see module docstring).")
    if _worker_running():
        j = _read_job()
        print(f"  Note: job already running ({j.get('basename') if j else '?'})")
    app.run(host=args.host, port=args.port, debug=False, threaded=True)
