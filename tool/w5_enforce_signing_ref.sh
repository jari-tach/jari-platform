#!/usr/bin/env bash
# Enforce W5 signing trust boundary: release branch or v* tag only.
# Optional: W5_ALLOW_TEST_SIGNING_ON_FIX=1 still refused for production jobs.
set -euo pipefail

REF="${1:-${GITHUB_REF:-}}"
MODE="${2:-production}" # production | test

if [[ -z "$REF" ]]; then
  echo "W5 FAIL: empty ref" >&2
  exit 1
fi

allowed=0
if [[ "$REF" == refs/heads/release/* ]]; then
  allowed=1
fi
if [[ "$REF" == refs/tags/v* ]]; then
  allowed=1
fi

if [[ "$allowed" -ne 1 ]]; then
  echo "W5 FAIL: signing refused for ref='$REF' (allowed: refs/heads/release/* or refs/tags/v*)" >&2
  echo "mode=$MODE event=${GITHUB_EVENT_NAME:-unknown}" >&2
  exit 1
fi

echo "W5 signing ref allowlist PASS ref=$REF mode=$MODE"
