#!/usr/bin/env bash
# Regenerate localizations: merge ARB fragments, then run gen-l10n.
#   tool/l10n.sh          merge lib/l10n/src/*.arb -> lib/l10n/app_*.arb -> lib/l10n/gen/*.dart
#   tool/l10n.sh --check  verify merged ARB + generated Dart are up to date (CI)
# See docs/i18n-guide.md.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "${1:-}" == "--check" ]]; then
  dart run tool/merge_arb.dart --check
  flutter gen-l10n
  if ! git diff --quiet -- lib/l10n/gen; then
    echo "lib/l10n/gen is stale. Run tool/l10n.sh and commit the result." >&2
    exit 1
  fi
  echo "l10n up to date."
  exit 0
fi

dart run tool/merge_arb.dart
flutter gen-l10n
dart format lib/l10n/gen >/dev/null
echo "l10n regenerated."
