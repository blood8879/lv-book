#!/usr/bin/env bash
#
# Google Play graphics for the ENGLISH listing (Lv Book)
# Source screenshots: en/raw/*.png captured from the real app (English locale)
# via integration_test/store_screenshots_test.dart on an iPhone simulator.
# 요구: ImageMagick 7 (magick), Pretendard 폰트
# 산출물: feature-graphic.png (1024x500) + screenshot-01~08.png (1080x1920)
#
# 사용법: docs/store/graphics/ 상위(레포 루트)에서 실행하거나 스크립트 위치 무관하게 동작.
set -euo pipefail

# --- 경로 ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
OUT="$SCRIPT_DIR/en"; mkdir -p "$OUT/raw"
SRC="$SCRIPT_DIR/en/raw"
FONT_DIR="$ROOT/assets/fonts"

BOLD="$FONT_DIR/Pretendard-Bold.otf"
SEMI="$FONT_DIR/Pretendard-SemiBold.otf"
REG="$FONT_DIR/Pretendard-Regular.otf"

# --- 브랜드 컬러 ---
DARK="#101010"
GREEN="#10B981"
BLUE="#3B82F6"
ORANGE="#FB923C"
SOFT="#F8F9FA"
INK="#111111"
SUBGRAY="#6B7280"
TAGLINE="#9AA49B"

# =====================================================================
# 1. FEATURE GRAPHIC  (1024 x 500)
# =====================================================================
echo "==> feature-graphic.png"

FG="$OUT/feature-graphic.png"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# 좌측 텍스트 + 우측 미니 표 장식을 한 번에 그린다.
# 우측 장식: 측량 표 열을 암시하는 라운드 사각형(패널 + 컬러 헤더 열 4개 + 로우 구분선)
magick -size 1024x500 "xc:$DARK" \
  -font "$BOLD"  -pointsize 82 -fill white        -gravity NorthWest -annotate +64+150 'Lv Book' \
  -font "$SEMI"  -pointsize 27 -fill "$TAGLINE"    -gravity NorthWest -annotate +66+258 'Leveling field book, from readings to report' \
  -fill "#181818" -stroke none -draw 'roundrectangle 690,120 968,392 18,18' \
  -fill "$GREEN"  -draw 'roundrectangle 712,146 772,240 8,8' \
  -fill "$BLUE"   -draw 'roundrectangle 782,146 842,300 8,8' \
  -fill "$ORANGE" -draw 'roundrectangle 852,146 912,206 8,8' \
  -fill "#2A2A2A" -draw 'roundrectangle 712,256 772,368 8,8' \
  -fill "#2A2A2A" -draw 'roundrectangle 782,316 842,368 8,8' \
  -fill "$GREEN"  -draw 'roundrectangle 852,222 912,368 8,8' \
  -fill "#242424" -stroke none \
    -draw 'rectangle 700,196 958,199' \
    -draw 'rectangle 700,262 958,265' \
    -draw 'rectangle 700,328 958,331' \
  "$TMP/fg_base.png"

# 컬러 pill 3개 (라운드 사각형 + 흰색 텍스트) — 텍스트 폭 측정 후 크기 산출
PILL_Y=316
PILL_H=50
GAP=16
PAD=22
x=64
declare -a PILL_TXT=('Auto HI/RL' 'PDF reports' 'Offline')
declare -a PILL_COL=("$GREEN" "$BLUE" "$ORANGE")

# base 위에 pill 을 순차적으로 그려 넣는다.
cp "$TMP/fg_base.png" "$TMP/fg_pills.png"
for i in 0 1 2; do
  txt="${PILL_TXT[$i]}"
  col="${PILL_COL[$i]}"
  tw=$(magick -background none -fill white -font "$SEMI" -pointsize 25 label:"$txt" -format '%w' info:)
  pw=$(( tw + PAD*2 ))
  x2=$(( x + pw ))
  y2=$(( PILL_Y + PILL_H ))
  # pill 배경
  magick "$TMP/fg_pills.png" \
    -fill "$col" -stroke none -draw "roundrectangle $x,$PILL_Y $x2,$y2 25,25" \
    "$TMP/fg_pills.png"
  # pill 텍스트(중앙)
  magick -background none -fill white -font "$SEMI" -pointsize 25 label:"$txt" "$TMP/pt.png"
  th=$(magick identify -format '%h' "$TMP/pt.png")
  tx=$(( x + (pw - tw)/2 ))
  ty=$(( PILL_Y + (PILL_H - th)/2 ))
  magick "$TMP/fg_pills.png" "$TMP/pt.png" -geometry "+${tx}+${ty}" -composite "$TMP/fg_pills.png"
  x=$(( x2 + GAP ))
done

# 알파 제거 + 8-bit 로 정규화 (Play feature graphic: 알파 없는 24-bit PNG)
magick "$TMP/fg_pills.png" -background "$DARK" -alpha remove -alpha off -depth 8 -strip "$FG"
magick identify "$FG"

# =====================================================================
# 2. SCREENSHOTS  (1080 x 1920)
# =====================================================================
# 캡션(상단 ~320px) + 목업(폭 860, 중앙, 은은한 그림자)
# 표: 번호 | 소스파일 | 헤드라인 | 서브 | 다크여부
render_shot () {
  local idx="$1" srcfile="$2" head="$3" sub="$4" dark="$5"
  local out="$OUT/screenshot-$idx.png"
  local bg headcol subcol
  if [ "$dark" = "1" ]; then
    bg="$DARK"; headcol="#FFFFFF"; subcol="$TAGLINE"
  else
    bg="$SOFT"; headcol="$INK"; subcol="$SUBGRAY"
  fi
  echo "==> screenshot-$idx.png ($srcfile)"

  # 목업 스케일(폭 860) + 그림자
  magick "$SRC/$srcfile" -resize 860x "$TMP/mk.png"
  magick "$TMP/mk.png" \( +clone -background black -shadow 45x22+0+14 \) \
    +swap -background none -layers merge +repage "$TMP/mks.png"

  # 배경 + 캡션 + 목업 합성
  magick -size 1080x1920 "xc:$bg" \
    -font "$BOLD" -pointsize 64 -fill "$headcol" -gravity North -annotate +0+96  "$head" \
    -font "$SEMI" -pointsize 36 -fill "$subcol"  -gravity North -annotate +0+188 "$sub" \
    "$TMP/mks.png" -gravity North -geometry +0+318 -composite \
    -background "$bg" -alpha remove -alpha off -depth 8 -strip \
    "$out"
  magick identify "$out"
}

render_shot 01 'editor.png'        'Enter readings, get levels'  'HI and RL reduced as you type BS/FS'      0
render_shot 02 'home.png'          'Every site in one place'     'Projects, level books and benchmarks'     0
render_shot 03 'levelbooks.png'    'Find, copy, export'          'Search and bulk export'                   0
render_shot 04 'benchmarks.png'    'Benchmarks with status'      'Usable, possibly damaged, out of service' 0
render_shot 05 'export.png'        'Submission-ready PDF'        'Preview before you print or share'        0
render_shot 06 'pdfsettings.png'   'Your company, your format'   'Company name, signature, watermark'       0
render_shot 07 'editor_dark.png'   'Dark mode'                   'Comfortable on site, day or night'        1

echo "==> done:"
ls -1 "$OUT"/*.png
