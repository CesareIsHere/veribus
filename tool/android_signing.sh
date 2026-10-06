#!/usr/bin/env bash
# Creates the Android signing key once and stores it as GitHub secrets, so every release APK carries the same
# signature and installs as an update over the previous one. Needs `keytool` (JDK) and the `gh` CLI, logged in.
#
#   bash tool/android_signing.sh [owner/repo]
#
# The keystore stays in ./veribus-release.jks: back it up, a lost key means users must uninstall to update.
set -euo pipefail

REPO=${1:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}
KEYSTORE=veribus-release.jks
ALIAS=veribus
PASSWORD=$(openssl rand -base64 24 | tr -d '/+=')

if [ -e "$KEYSTORE" ]; then echo "$KEYSTORE already exists: not overwriting it" >&2; exit 1; fi

keytool -genkeypair -v -keystore "$KEYSTORE" -alias "$ALIAS" -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$PASSWORD" -keypass "$PASSWORD" -dname "CN=Veribus"

base64 -w0 "$KEYSTORE" 2>/dev/null | gh secret set ANDROID_KEYSTORE_BASE64 --repo "$REPO" \
  || base64 -i "$KEYSTORE" | gh secret set ANDROID_KEYSTORE_BASE64 --repo "$REPO"
gh secret set ANDROID_KEYSTORE_PASSWORD --repo "$REPO" --body "$PASSWORD"
gh secret set ANDROID_KEY_ALIAS --repo "$REPO" --body "$ALIAS"
gh secret set ANDROID_KEY_PASSWORD --repo "$REPO" --body "$PASSWORD"

echo "Secrets set on $REPO. Keep $KEYSTORE and this password somewhere safe: $PASSWORD"
