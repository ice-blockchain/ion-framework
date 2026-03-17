#!/bin/bash
set -euo pipefail

source "$(dirname "$0")/utils.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/auto_translate_locales.sh [--commit] [--fail-if-generated] [--base-ref=<ref>|--base-ref=auto]

Behavior:
  - Runs flutter gen-l10n
  - If untranslated_messages.txt is non-empty OR app_en.arb changed vs base ref, runs tools/translate_missing.dart
  - Re-runs flutter gen-l10n
  - Runs scripts/generate_locales.sh verification

Options:
  --commit              Pass --commit to translate_missing.dart (CI use).
  --fail-if-generated   Exit 1 if translations were generated (pre-push use).
  --base-ref=<ref>      Git ref to compare for app_en.arb changes (default: env BASE_REF, else auto).
  --base-ref=auto       Auto-pick origin/master or origin/main if available.
EOF
}

DO_COMMIT=0
FAIL_IF_GENERATED=0
BASE_REF_ARG=""

for arg in "$@"; do
  case "$arg" in
    --commit) DO_COMMIT=1 ;;
    --fail-if-generated) FAIL_IF_GENERATED=1 ;;
    --base-ref=*) BASE_REF_ARG="${arg#--base-ref=}" ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $arg" >&2; usage; exit 2 ;;
  esac
done

# 1) Generate l10n (produces untranslated_messages.txt)
use_asdf flutter gen-l10n

UNTRANSLATED_FILE="untranslated_messages.txt"
NEED_TRANSLATIONS=0
L10N_STATUS_BEFORE="$(git status --porcelain lib/l10n 2>/dev/null || true)"

if [ -f "$UNTRANSLATED_FILE" ] && [ -s "$UNTRANSLATED_FILE" ] && [ "$(jq 'length' "$UNTRANSLATED_FILE" 2>/dev/null)" != "0" ]; then
  NEED_TRANSLATIONS=1
fi

BASE_REF="${BASE_REF_ARG:-${BASE_REF:-}}"
if [ "$NEED_TRANSLATIONS" -eq 0 ]; then
  if [ -z "$BASE_REF" ] || [ "$BASE_REF" = "auto" ]; then
    if git show "origin/master:lib/l10n/app_en.arb" >/dev/null 2>&1; then
      BASE_REF="origin/master"
    elif git show "origin/main:lib/l10n/app_en.arb" >/dev/null 2>&1; then
      BASE_REF="origin/main"
    else
      BASE_REF=""
    fi
  fi

  if [ -n "$BASE_REF" ] && ! git diff --quiet "$BASE_REF" -- lib/l10n/app_en.arb 2>/dev/null; then
    NEED_TRANSLATIONS=1
  fi
fi

GENERATED=0
if [ "$NEED_TRANSLATIONS" -eq 1 ]; then
  if [ -n "$BASE_REF" ]; then
    export BASE_REF="$BASE_REF"
  fi

  if [ "$DO_COMMIT" -eq 1 ]; then
    dart run tools/translate_missing.dart --commit
  else
    dart run tools/translate_missing.dart
  fi

  # Re-run gen-l10n after filling so untranslated_messages.txt is refreshed.
  use_asdf flutter gen-l10n
fi

# 4) Verify
./scripts/generate_locales.sh

# Only fail pre-push when this script actually produced new l10n changes.
L10N_STATUS_AFTER="$(git status --porcelain lib/l10n 2>/dev/null || true)"
if [ "$L10N_STATUS_AFTER" != "$L10N_STATUS_BEFORE" ]; then
  GENERATED=1
fi

if [ "$GENERATED" -eq 1 ] && [ "$FAIL_IF_GENERATED" -eq 1 ]; then
  exit 1
fi

exit 0

