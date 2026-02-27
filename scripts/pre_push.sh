#!/bin/bash

printf "\e[33;1m%s\e[0m\n" 'Pre-Push'

# Check Xcode Version
XCODE_VERSION_FILE=".xcode-version"
if [ -f "$XCODE_VERSION_FILE" ]; then
  REQUIRED_VERSION=$(cat "$XCODE_VERSION_FILE" | tr -d '[:space:]')
  CURRENT_VERSION=$(xcodebuild -version 2>/dev/null | head -1 | sed 's/Xcode //')
  if [ "$CURRENT_VERSION" != "$REQUIRED_VERSION" ]; then
    printf "\e[31;1m%s\e[0m\n" "=== Xcode version mismatch ==="
    printf "\e[31;1m%s\e[0m\n" "Required: $REQUIRED_VERSION (from $XCODE_VERSION_FILE)"
    printf "\e[31;1m%s\e[0m\n" "Current:  $CURRENT_VERSION"
    printf "\e[31;1m%s\e[0m\n" "Please switch to Xcode $REQUIRED_VERSION to avoid project.pbxproj conflicts."
    exit 1
  fi
  printf "\e[33;1m%s\e[0m\n" "Xcode version OK ($CURRENT_VERSION)"
fi

# Format Code
printf "\e[33;1m%s\e[0m\n" '=== Format Code ==='
melos run 4mat
if [ $? -ne 0 ]; then
  printf "\e[31;1m%s\e[0m\n" '=== Format Code changes ==='
  exit 1
fi
printf "\e[33;1m%s\e[0m\n" 'Finished running Format Code'
printf '%s\n' "${avar}"

# Generate Code
printf "\e[33;1m%s\e[0m\n" '=== Generate Code ==='
scripts/generate_code.sh
if [ $? -ne 0 ]; then
  printf "\e[31;1m%s\e[0m\n" '=== Generate Code error ==='
  exit 1
fi
printf "\e[33;1m%s\e[0m\n" 'Finished running Generate Code'
printf '%s\n' "${avar}"

# Generate Locales
printf "\e[33;1m%s\e[0m\n" '=== Generate Locales ==='
scripts/generate_locales.sh
if [ $? -ne 0 ]; then
  printf "\e[31;1m%s\e[0m\n" '=== Generate locales error ==='
  exit 1
fi
printf "\e[33;1m%s\e[0m\n" 'Finished running Generate Locales'
printf '%s\n' "${avar}"

# Check License
printf "\e[33;1m%s\e[0m\n" '=== Check License ==='
scripts/license_check.sh
if [ $? -ne 0 ]; then
  printf "\e[31;1m%s\e[0m\n" '=== Check License error ==='
  exit 1
fi
printf "\e[33;1m%s\e[0m\n" 'Finished running Check License'
printf '%s\n' "${avar}"

# Flutter Analyzer
printf "\e[33;1m%s\e[0m\n" '=== Running Flutter analyzer ==='
melos run analyze
if [ $? -ne 0 ]; then
  printf "\e[31;1m%s\e[0m\n" '=== Flutter analyzer error ==='
  exit 1
fi
printf "\e[33;1m%s\e[0m\n" 'Finished running Flutter analyzer'
printf '%s\n' "${avar}"

# Run Tests
printf "\e[33;1m%s\e[0m\n" '=== Run Tests ==='
melos run test
if [ $? -ne 0 ]; then
  printf "\e[31;1m%s\e[0m\n" '=== Run Tests error ==='
  exit 1
fi
printf "\e[33;1m%s\e[0m\n" 'Finished running Run Tests'
printf '%s\n' "${avar}"

# If we made it this far, the commit is pushed
exit 0
