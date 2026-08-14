#!/usr/bin/env bash
# W5 — verify Android AAB (+ optional proof APK) against ANDROID_UPLOAD_CERT_SHA256.
# Usage: w5_verify_android_artifacts.sh <aab> [apk] [provenance_out]
set -euo pipefail

normalize_sha() {
  echo "$1" | tr '[:lower:]' '[:upper:]' | tr -d '[:space:]:'
}

AAB="${1:?aab path required}"
APK="${2:-}"
PROV_OUT="${3:-provenance-w5-android.txt}"
EXPECTED_RAW="${ANDROID_UPLOAD_CERT_SHA256:?ANDROID_UPLOAD_CERT_SHA256 is required (outside Git)}"
EXPECTED="$(normalize_sha "$EXPECTED_RAW")"
if [[ ${#EXPECTED} -ne 64 ]]; then
  echo "ANDROID_UPLOAD_CERT_SHA256 must be 64 hex chars (optionally colon-separated)" >&2
  exit 1
fi
if [[ ! -f "$AAB" ]]; then
  echo "missing AAB: $AAB" >&2
  exit 1
fi

echo "jarsigner -verify (AAB)"
jarsigner -verify -verbose -certs "$AAB" >/tmp/w5-aab-jarsigner.txt
if grep -qi 'CN=Android Debug' /tmp/w5-aab-jarsigner.txt; then
  echo "W5 FAIL: debug certificate detected in AAB" >&2
  exit 1
fi

# Extract signer SHA-256 from JAR signing block (first certificate).
CERT_TMP="$(mktemp)"
# Prefer META-INF RSA/DSA/EC block
set +e
RSA_ENTRY="$(unzip -Z1 "$AAB" | grep -E '^META-INF/.*\.(RSA|DSA|EC)$' | head -n1)"
set -e
if [[ -z "${RSA_ENTRY:-}" ]]; then
  echo "W5 FAIL: no META-INF signing block in AAB" >&2
  exit 1
fi
unzip -p "$AAB" "$RSA_ENTRY" >"$CERT_TMP"
KEYTOOL_OUT="$(keytool -printcert -file "$CERT_TMP" 2>/dev/null || true)"
AAB_SHA_LINE="$(echo "$KEYTOOL_OUT" | grep -i 'SHA256:' | head -n1 || true)"
if [[ -z "$AAB_SHA_LINE" ]]; then
  # Some keytool builds print "Certificate fingerprints:" then "SHA-256:"
  AAB_SHA_LINE="$(echo "$KEYTOOL_OUT" | grep -iE 'SHA-?256' | head -n1 || true)"
fi
AAB_SHA="$(normalize_sha "$(echo "$AAB_SHA_LINE" | sed -E 's/.*SHA-?256[: ]*//I')")"
if [[ ${#AAB_SHA} -ne 64 ]]; then
  echo "W5 FAIL: could not parse AAB signer SHA-256" >&2
  echo "$KEYTOOL_OUT" >&2
  exit 1
fi
if [[ "$AAB_SHA" != "$EXPECTED" ]]; then
  echo "W5 FAIL: AAB signer SHA-256 mismatch" >&2
  echo "expected=$EXPECTED" >&2
  echo "actual=$AAB_SHA" >&2
  exit 1
fi
echo "AAB signer SHA-256 matches ANDROID_UPLOAD_CERT_SHA256"

APK_SHA=""
if [[ -n "$APK" ]]; then
  if [[ ! -f "$APK" ]]; then
    echo "missing APK: $APK" >&2
    exit 1
  fi
  APKSIGNER="$(command -v apksigner || true)"
  if [[ -z "$APKSIGNER" && -n "${ANDROID_HOME:-}" ]]; then
    APKSIGNER="$(ls -1 "$ANDROID_HOME"/build-tools/*/apksigner 2>/dev/null | sort -V | tail -n1 || true)"
  fi
  if [[ -z "$APKSIGNER" ]]; then
    echo "W5 FAIL: apksigner not found" >&2
    exit 1
  fi
  echo "apksigner verify --verbose --print-certs"
  "$APKSIGNER" verify --verbose --print-certs "$APK" | tee /tmp/w5-apk-apksigner.txt
  if grep -qi 'CN=Android Debug' /tmp/w5-apk-apksigner.txt; then
    echo "W5 FAIL: debug certificate detected in APK" >&2
    exit 1
  fi
  APK_SHA_LINE="$(grep -i 'Signer #1 certificate SHA-256 digest:' /tmp/w5-apk-apksigner.txt | head -n1 || true)"
  APK_SHA="$(normalize_sha "$(echo "$APK_SHA_LINE" | sed -E 's/.*SHA-256 digest:[[:space:]]*//I')")"
  if [[ ${#APK_SHA} -ne 64 ]]; then
    echo "W5 FAIL: could not parse APK signer SHA-256" >&2
    exit 1
  fi
  if [[ "$APK_SHA" != "$EXPECTED" ]]; then
    echo "W5 FAIL: APK signer SHA-256 mismatch" >&2
    echo "expected=$EXPECTED" >&2
    echo "actual=$APK_SHA" >&2
    exit 1
  fi
  if [[ "$APK_SHA" != "$AAB_SHA" ]]; then
    echo "W5 FAIL: APK/AAB signer fingerprints differ" >&2
    exit 1
  fi
  echo "APK signer SHA-256 matches"
fi

AAB_HASH="$(sha256sum "$AAB" | awk '{print $1}')"
{
  echo "artifact=aab"
  echo "aab_path=$AAB"
  echo "aab_sha256=$AAB_HASH"
  echo "signer_cert_sha256=$AAB_SHA"
  if [[ -n "$APK" ]]; then
    echo "artifact_apk=apk"
    echo "apk_path=$APK"
    echo "apk_sha256=$(sha256sum "$APK" | awk '{print $1}')"
    echo "apk_signer_cert_sha256=$APK_SHA"
  fi
} | tee "$PROV_OUT"

rm -f "$CERT_TMP"
echo "W5 Android artifact verify PASS"
