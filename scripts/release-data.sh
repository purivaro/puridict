#!/usr/bin/env bash
# Publish ข้อมูลพจนานุกรมขึ้น GitHub Release ให้แอพที่ติดตั้งแล้วโหลดไปใช้ได้เลย
# (ไม่ต้องรอรีวิวสโตร์ — ใช้กับการแก้คำแปล/ข้อมูล ไม่ใช่การแก้โค้ด)
#
# ใช้:
#   ./scripts/release-data.sh forms                 # ปล่อยเฉพาะสะพานรูปคำผัน
#   ./scripts/release-data.sh forms combined        # ปล่อยหลายคลัง
#   ./scripts/release-data.sh --version=2026.08.22 forms
#
# ต้องมี: gh CLI (login แล้ว) · sqlite3 · jq · cwd อยู่ใน repo ที่ผูก GitHub remote
#
# manifest.json เป็น "แบบสะสม" — ทุกครั้งจะดึงของ release ก่อนหน้ามารวม
# แล้วทับเฉพาะคลังที่ปล่อยรอบนี้ เพราะแอพอ่าน releases/latest/download/manifest.json
# ไฟล์เดียว ถ้าเขียนเฉพาะคลังที่เพิ่งแก้ คลังอื่นจะหายไปจากสายตาแอพทันที

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA_DIR="$REPO_ROOT/assets/data"
VERSION=""
DATASETS=()

for arg in "$@"; do
  case "$arg" in
    --version=*) VERSION="${arg#--version=}" ;;
    -*)          echo "unknown option: $arg" >&2; exit 1 ;;
    *)           DATASETS+=("$arg") ;;
  esac
done

if [[ ${#DATASETS[@]} -eq 0 ]]; then
  echo "usage: $0 [--version=YYYY.MM.DD] <dataset...>   (combined | forms | mungkala)" >&2
  exit 1
fi

VERSION="${VERSION:-$(date +%Y.%m.%d)}"
# แอพเทียบเวอร์ชันด้วยการเรียงตัวอักษร รูปแบบวันที่จึงต้องคงที่
# ปล่อยซ้ำวันเดียวกันให้ใส่ .2 .3 ต่อท้าย (2026.08.22.2 > 2026.08.22)
if [[ ! "$VERSION" =~ ^[0-9]{4}\.[0-9]{2}\.[0-9]{2}(\.[0-9]+)?$ ]]; then
  echo "error: version ต้องเป็น YYYY.MM.DD หรือ YYYY.MM.DD.N (ได้: $VERSION)" >&2
  exit 1
fi

for d in "${DATASETS[@]}"; do
  case "$d" in
    combined|forms|mungkala) ;;
    *) echo "error: ไม่รู้จักคลัง '$d' (ใช้ได้: combined forms mungkala)" >&2; exit 1 ;;
  esac
  [[ -f "$DATA_DIR/$d.sqlite" ]] || { echo "error: ไม่พบ $DATA_DIR/$d.sqlite" >&2; exit 1; }
done

command -v gh      >/dev/null || { echo "error: ต้องมี gh CLI" >&2; exit 1; }
command -v jq      >/dev/null || { echo "error: ต้องมี jq" >&2; exit 1; }
command -v sqlite3 >/dev/null || { echo "error: ต้องมี sqlite3" >&2; exit 1; }

OWNER_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
TAG="data-v${VERSION}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

filesize() { stat -f%z "$1" 2>/dev/null || stat -c%s "$1"; }

# ── ตรวจของก่อนปล่อย ────────────────────────────────────────────────
# ปล่อยไฟล์เสียขึ้นไปแล้วแอพจะกู้ตัวเองได้ก็จริง แต่ผู้ใช้เสียเน็ตฟรี
declare -a UPLOAD_FILES=()
ENTRIES="{}"

for d in "${DATASETS[@]}"; do
  SQLITE="$DATA_DIR/$d.sqlite"
  echo "→ [$d] ตรวจไฟล์ต้นทาง..."
  CHECK=$(sqlite3 "$SQLITE" 'PRAGMA quick_check(1)')
  [[ "$CHECK" == "ok" ]] || { echo "error: $d.sqlite เสีย ($CHECK)" >&2; exit 1; }

  case "$d" in
    combined) PROBE='SELECT count(*) FROM entries' ;;
    forms)    PROBE='SELECT count(*) FROM forms' ;;
    mungkala) PROBE='SELECT count(*) FROM pairs' ;;
  esac
  ROWS=$(sqlite3 "$SQLITE" "$PROBE")
  [[ "$ROWS" -gt 0 ]] || { echo "error: $d.sqlite ไม่มีข้อมูล" >&2; exit 1; }
  echo "   ok · $(printf "%'d" "$ROWS") แถว"

  GZ_NAME="${d}-${VERSION}.sqlite.gz"
  GZ_PATH="$TMP_DIR/$GZ_NAME"
  SRC_SHA=$(shasum -a 256 "$SQLITE" | awk '{print $1}')

  # ใช้ .gz ที่ bundle อยู่ในแอพถ้าตรงกับ .sqlite จริง (ผู้ใช้จะได้ไฟล์ชุดเดียวกันเป๊ะ)
  # ไม่ตรง/ไม่มี ค่อยบีบใหม่ — กันกรณีลืม regenerate หลัง copy ไฟล์ใหม่มา
  if [[ -f "$DATA_DIR/$d.sqlite.gz" ]] &&
     [[ "$(gzip -cd "$DATA_DIR/$d.sqlite.gz" | shasum -a 256 | awk '{print $1}')" == "$SRC_SHA" ]]; then
    cp "$DATA_DIR/$d.sqlite.gz" "$GZ_PATH"
    echo "   ใช้ $d.sqlite.gz ที่มีอยู่ (ตรงกับ .sqlite)"
  else
    echo "   บีบไฟล์ใหม่ (gzip -9)..."
    gzip -9 -c "$SQLITE" > "$GZ_PATH"
    cp "$GZ_PATH" "$DATA_DIR/$d.sqlite.gz"
    echo "   อัปเดต $d.sqlite.gz ใน repo ด้วย — อย่าลืม commit"
  fi

  SIZE=$(filesize "$GZ_PATH")
  SHA=$(shasum -a 256 "$GZ_PATH" | awk '{print $1}')
  UPLOAD_FILES+=("$GZ_PATH")

  ENTRIES=$(jq -n --argjson acc "$ENTRIES" --arg k "$d" \
    --arg v "$VERSION" --argjson size "$SIZE" --arg sha "$SHA" \
    --arg url "https://github.com/${OWNER_REPO}/releases/download/${TAG}/${GZ_NAME}" \
    '$acc + {($k): {version:$v, size:$size, sha256:$sha, url:$url}}')
done

# ── รวมกับ manifest ของ release ก่อนหน้า ────────────────────────────
PREV="{}"
if curl -fsSL --max-time 20 \
      "https://github.com/${OWNER_REPO}/releases/latest/download/manifest.json" \
      -o "$TMP_DIR/prev.json" 2>/dev/null; then
  PREV=$(jq 'if .datasets then .datasets else {combined: .} end' "$TMP_DIR/prev.json" 2>/dev/null || echo '{}')
  echo "→ รวมกับ manifest เดิม: $(jq -r 'keys | join(", ")' <<<"$PREV")"
else
  echo "→ ยังไม่มี release เดิม — สร้าง manifest ใหม่"
fi

MANIFEST="$TMP_DIR/manifest.json"
# ฟิลด์ระดับบนสุด = คลัง combined สำหรับแอพรุ่นเก่า (≤2.1.0) ที่อ่าน manifest แบบคลังเดียว
jq -n --argjson prev "$PREV" --argjson new "$ENTRIES" '
  ($prev + $new) as $ds
  | {datasets: $ds}
  + (if $ds.combined then $ds.combined else {} end)
' > "$MANIFEST"

echo "→ manifest:"
jq . "$MANIFEST"
echo

# ── ปล่อยขึ้น GitHub ────────────────────────────────────────────────
if gh release view "$TAG" >/dev/null 2>&1; then
  echo "→ release $TAG มีอยู่แล้ว — อัปโหลดทับ"
  gh release upload "$TAG" "${UPLOAD_FILES[@]}" "$MANIFEST" --clobber
else
  echo "→ สร้าง release ${TAG}..."
  gh release create "$TAG" "${UPLOAD_FILES[@]}" "$MANIFEST" \
    --title "Dictionary data ${VERSION}" \
    --notes "คลังที่อัปเดตรอบนี้: ${DATASETS[*]}"$'\n\n'"publish โดย scripts/release-data.sh"
fi

echo "✓ เสร็จแล้ว — แอพจะเห็นภายในรอบเช็คถัดไป (อย่างช้า 6 ชั่วโมง) หรือกด 'ตรวจอัปเดต' ในหน้าเกี่ยวกับแอพ"
