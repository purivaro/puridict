#!/usr/bin/env bash
# Publish dictionary data update เป็น GitHub Release
#
# Usage:
#   ./scripts/release-data.sh 2026.05.10
#
# ต้อง:
#   - มี gh CLI ติดตั้งและ login (`gh auth login`) แล้ว
#   - cwd เป็น root ของ repo ที่ผูกกับ GitHub remote ไว้แล้ว
#   - มี assets/data/combined.sqlite พร้อม publish

set -euo pipefail

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
  echo "usage: $0 <version>   (e.g. 2026.05.10)" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$REPO_ROOT/assets/data"
SQLITE="$DATA_DIR/combined.sqlite"

if [[ ! -f "$SQLITE" ]]; then
  echo "error: $SQLITE not found" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

GZ_NAME="combined-${VERSION}.sqlite.gz"
GZ_PATH="$TMP_DIR/$GZ_NAME"
MANIFEST_PATH="$TMP_DIR/manifest.json"

echo "→ gzip (max compression)..."
gzip -9 -c "$SQLITE" > "$GZ_PATH"

SIZE=$(stat -f%z "$GZ_PATH" 2>/dev/null || stat -c%s "$GZ_PATH")
SHA=$(shasum -a 256 "$GZ_PATH" | awk '{print $1}')

# resolve owner/repo จาก gh
OWNER_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
TAG="data-v${VERSION}"
DOWNLOAD_URL="https://github.com/${OWNER_REPO}/releases/download/${TAG}/${GZ_NAME}"

cat > "$MANIFEST_PATH" <<EOF
{
  "version": "${VERSION}",
  "size": ${SIZE},
  "sha256": "${SHA}",
  "url": "${DOWNLOAD_URL}"
}
EOF

echo "→ manifest:"
cat "$MANIFEST_PATH"
echo

echo "→ creating release ${TAG}..."
gh release create "$TAG" \
  "$GZ_PATH" \
  "$MANIFEST_PATH" \
  --title "Dictionary data ${VERSION}" \
  --notes "Auto-published by release-data.sh"

echo "✓ done. clients will pick this up on next launch (within 6h throttle)."
