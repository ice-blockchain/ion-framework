#!/bin/bash

source "$(dirname "$0")/utils.sh"

# https://pub.dev/packages/flutter_gen
# https://pub.dev/packages/freezed
# https://pub.dev/packages/json_serializable
# https://pub.dev/packages/widgetbook

# Run build_runner in every package that has it (so root build can read their generated assets)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
while IFS= read -r -d '' pubspec; do
  pkg_dir="$(dirname "$pubspec")"
  if grep -q "build_runner" "$pubspec"; then
    (cd "$pkg_dir" && use_asdf dart run build_runner clean && use_asdf dart run build_runner build --delete-conflicting-outputs)
  fi
done < <(find "$REPO_ROOT/packages" -name "pubspec.yaml" -not -path "*/example/*" -print0 2>/dev/null)

cd "$REPO_ROOT"
use_asdf dart run build_runner clean
use_asdf dart run build_runner build --delete-conflicting-outputs

