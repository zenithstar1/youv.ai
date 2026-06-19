#!/usr/bin/env bash
# Production Flutter Web build with deployment-safe caching.
# Usage: ./tool/build_web.sh

set -euo pipefail
cd "$(dirname "$0")/.."

echo "Building Flutter Web (service worker disabled)..."
flutter build web --release --pwa-strategy=none "$@"

BUILD_DIR="build/web"
LAST_BUILD_ID_FILE="${BUILD_DIR}/.last_build_id"

if [[ ! -f "${LAST_BUILD_ID_FILE}" ]]; then
  echo "Missing ${LAST_BUILD_ID_FILE}" >&2
  exit 1
fi

BUILD_ID="$(tr -d '\r\n' < "${LAST_BUILD_ID_FILE}")"
printf '{"build_id":"%s"}' "${BUILD_ID}" > "${BUILD_DIR}/build_id.json"

echo "Wrote ${BUILD_DIR}/build_id.json => ${BUILD_ID}"
echo "Deploy the entire build/web directory."
