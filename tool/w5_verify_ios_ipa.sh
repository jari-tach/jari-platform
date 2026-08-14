#!/usr/bin/env bash
# W5 — fail-closed iOS IPA verification (Distribution only).
# Required env (outside Git): APPLE_TEAM_ID, IOS_BUNDLE_ID, APPLE_DISTRIBUTION_CERT_SHA256
# Usage: w5_verify_ios_ipa.sh <ipa> [provenance_out]
set -euo pipefail

normalize_sha() {
  echo "$1" | tr '[:lower:]' '[:upper:]' | tr -d '[:space:]:'
}

IPA="${1:?ipa path required}"
PROV_OUT="${2:-provenance-w5-ios.txt}"
TEAM_ID="${APPLE_TEAM_ID:?APPLE_TEAM_ID required}"
BUNDLE_ID="${IOS_BUNDLE_ID:?IOS_BUNDLE_ID required}"
EXPECTED="$(normalize_sha "${APPLE_DISTRIBUTION_CERT_SHA256:?APPLE_DISTRIBUTION_CERT_SHA256 required}")"

if [[ ! -f "$IPA" ]]; then
  echo "missing IPA: $IPA" >&2
  exit 1
fi
if [[ ${#EXPECTED} -ne 64 ]]; then
  echo "APPLE_DISTRIBUTION_CERT_SHA256 must be 64 hex chars" >&2
  exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
unzip -q "$IPA" -d "$WORK"
APP="$(echo "$WORK"/Payload/*.app)"
if [[ ! -d "$APP" ]]; then
  echo "W5 FAIL: no Payload/*.app in IPA" >&2
  exit 1
fi

echo "codesign --verify --deep --strict"
codesign --verify --deep --strict "$APP"

CODESIGN_OUT="$(codesign -dvv "$APP" 2>&1 || true)"
echo "$CODESIGN_OUT" | tee "$WORK/codesign.txt"

AUTHORITY="$(echo "$CODESIGN_OUT" | grep -i 'Authority=' | head -n1 || true)"
if ! echo "$AUTHORITY" | grep -qi 'Apple Distribution'; then
  echo "W5 FAIL: expected Apple Distribution authority, got: $AUTHORITY" >&2
  exit 1
fi
if echo "$CODESIGN_OUT" | grep -qi 'Authority=Apple Development'; then
  echo "W5 FAIL: Apple Development identity forbidden for store IPA" >&2
  exit 1
fi

TEAM_LINE="$(echo "$CODESIGN_OUT" | grep -i 'TeamIdentifier=' | head -n1 || true)"
ACTUAL_TEAM="$(echo "$TEAM_LINE" | sed -E 's/.*=//')"
if [[ "$ACTUAL_TEAM" != "$TEAM_ID" ]]; then
  echo "W5 FAIL: TeamIdentifier mismatch expected=$TEAM_ID actual=$ACTUAL_TEAM" >&2
  exit 1
fi

PROFILE="$APP/embedded.mobileprovision"
if [[ ! -f "$PROFILE" ]]; then
  echo "W5 FAIL: missing embedded.mobileprovision" >&2
  exit 1
fi
security cms -D -i "$PROFILE" >"$WORK/profile.plist" 2>/dev/null

/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' "$WORK/profile.plist" >"$WORK/appid.txt"
APP_ID="$(tr -d '[:space:]' <"$WORK/appid.txt")"
EXPECTED_APP_ID="${TEAM_ID}.${BUNDLE_ID}"
if [[ "$APP_ID" != "$EXPECTED_APP_ID" ]]; then
  echo "W5 FAIL: application-identifier mismatch expected=$EXPECTED_APP_ID actual=$APP_ID" >&2
  exit 1
fi

GET_TASK="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:get-task-allow' "$WORK/profile.plist" 2>/dev/null || echo missing)"
if [[ "$GET_TASK" != "false" ]]; then
  echo "W5 FAIL: get-task-allow must be false (got: $GET_TASK)" >&2
  exit 1
fi

python3 - "$WORK/profile.plist" <<'PY'
import sys, plistlib
from datetime import datetime, timezone
path = sys.argv[1]
with open(path, "rb") as f:
    data = plistlib.load(f)
exp = data.get("ExpirationDate")
if exp is None:
    raise SystemExit("missing ExpirationDate")
if exp.tzinfo is None:
    exp = exp.replace(tzinfo=timezone.utc)
now = datetime.now(timezone.utc)
if exp <= now:
    raise SystemExit(f"profile expired: {exp.isoformat()}")
print(f"profile_expires={exp.isoformat()}")
PY

codesign -d --extract-certificates="$WORK/cert" "$APP" 2>/dev/null || true
SIGNER_CERT="$WORK/cert0"
if [[ ! -f "$SIGNER_CERT" ]]; then
  echo "W5 FAIL: could not extract signer certificate via codesign" >&2
  exit 1
fi
ACTUAL_FP="$(openssl x509 -inform DER -in "$SIGNER_CERT" -noout -fingerprint -sha256 \
  | sed -E 's/.*=//' )"
ACTUAL_FP="$(normalize_sha "$ACTUAL_FP")"
if [[ "$ACTUAL_FP" != "$EXPECTED" ]]; then
  echo "W5 FAIL: distribution cert SHA-256 mismatch" >&2
  echo "expected=$EXPECTED" >&2
  echo "actual=$ACTUAL_FP" >&2
  exit 1
fi

openssl x509 -inform DER -in "$SIGNER_CERT" -noout -checkend 0 >/dev/null \
  || { echo "W5 FAIL: distribution certificate expired" >&2; exit 1; }

IPA_HASH="$(shasum -a 256 "$IPA" | awk '{print $1}')"
{
  echo "artifact=ipa"
  echo "ipa_sha256=$IPA_HASH"
  echo "signer_cert_sha256=$ACTUAL_FP"
  echo "team_id=$TEAM_ID"
  echo "bundle_id=$BUNDLE_ID"
  echo "application_identifier=$APP_ID"
  echo "get_task_allow=false"
} | tee "$PROV_OUT"

echo "W5 iOS IPA verify PASS"
