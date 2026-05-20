#!/usr/bin/env bash
# Sync DAILY_FIT_ENGINE_ID from repo-root .env into Dev.xcconfig / Prod.xcconfig.
# Patches only DAILY_FIT_ENGINE_ID — never Supabase keys or other xcconfig values.
set -euo pipefail

usage() {
  cat <<'EOF'
Sync DAILY_FIT_ENGINE_ID from .env into Dev.xcconfig / Prod.xcconfig.

Reads the repository-root .env and patches only DAILY_FIT_ENGINE_ID in each
existing xcconfig under Cosmic Fit/Config/. Other keys are never modified.

Usage:
  tools/sync_env_to_xcconfig.sh [--dry-run]

Options:
  --dry-run   Print planned changes without writing files
  -h, --help  Show this help

Requires:
  .env with DAILY_FIT_ENGINE_ID=<slug> (e.g. production, legacy_baseline)
  At least one of Dev.xcconfig or Prod.xcconfig (copy from Dev.xcconfig.example)
EOF
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT}/.env"
CONFIG_DIR="${ROOT}/Cosmic Fit/Config"
KEY="DAILY_FIT_ENGINE_ID"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

read_env_value() {
  local file="$1"
  local env_key="$2"
  local line value

  if [[ ! -f "$file" ]]; then
    echo "error: .env not found at ${file}" >&2
    echo "Copy .env.example to .env and set ${KEY}." >&2
    exit 1
  fi

  line="$(grep -E "^[[:space:]]*${env_key}[[:space:]]*=" "$file" | tail -n 1 || true)"
  if [[ -z "$line" ]]; then
    echo "error: ${env_key} not set in .env" >&2
    exit 1
  fi

  value="${line#*=}"
  value="$(printf '%s' "$value" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/^["'\''](.*)["'\'']$/\1/')"

  if [[ ! "$value" =~ ^[a-z][a-z0-9_]*$ ]]; then
    echo "error: invalid ${env_key} value '${value}' (expected slug like production)" >&2
    exit 1
  fi

  printf '%s' "$value"
}

patch_xcconfig() {
  local path="$1"
  local value="$2"
  local basename new_line current

  basename="$(basename "$path")"
  new_line="${KEY} = ${value}"

  if [[ ! -f "$path" ]]; then
    echo "skip: ${basename} (file not found)"
    return 0
  fi

  if grep -qE "^[[:space:]]*${KEY}[[:space:]]*=" "$path"; then
    current="$(grep -E "^[[:space:]]*${KEY}[[:space:]]*=" "$path" | tail -n 1 | sed -E 's/^[[:space:]]*[^=]*=[[:space:]]*//')"
    if [[ "$current" == "$value" ]]; then
      echo "ok: ${basename} already ${new_line}"
      return 0
    fi
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "would update: ${basename} -> ${new_line}"
      return 0
    fi
    local tmp
    tmp="$(mktemp "${path}.sync.XXXXXX")"
    sed -E "s|^[[:space:]]*${KEY}[[:space:]]*=[[:space:]]*.*|${new_line}|" "$path" > "$tmp"
    mv "$tmp" "$path"
    echo "updated: ${basename} -> ${new_line}"
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "would append: ${basename} -> ${new_line}"
    return 0
  fi

  {
    printf '\n// Daily Fit engine preset (synced from .env via tools/sync_env_to_xcconfig.sh)\n'
    printf '%s\n' "$new_line"
  } >>"$path"
  echo "appended: ${basename} -> ${new_line}"
}

ENGINE_ID="$(read_env_value "$ENV_FILE" "$KEY")"
echo "DAILY_FIT_ENGINE_ID from .env: ${ENGINE_ID}"

found=0
for name in Dev.xcconfig Prod.xcconfig; do
  path="${CONFIG_DIR}/${name}"
  if [[ -f "$path" ]]; then
    found=1
    patch_xcconfig "$path" "$ENGINE_ID"
  else
    echo "skip: ${name} (file not found)"
  fi
done

if [[ "$found" -eq 0 ]]; then
  echo "error: no xcconfig files found under Cosmic Fit/Config/" >&2
  echo "Copy Dev.xcconfig.example to Dev.xcconfig and fill in Supabase credentials first." >&2
  exit 1
fi
