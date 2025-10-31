#!/bin/bash

source "$(dirname "$0")/utils.sh"

# Parse command line arguments
VERIFY=false
STRICT=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --verify)
      VERIFY=true
      shift
      ;;
    --strict)
      STRICT=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [--verify] [--strict]"
      echo ""
      echo "Options:"
      echo "  --verify    Run localization verification after generation"
      echo "  --strict    Exit with error if missing translations found (requires --verify)"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# https://docs.flutter.dev/ui/accessibility-and-localization/internationalization
use_asdf flutter gen-l10n

# Run verification if requested
if [ "$VERIFY" = true ]; then
  SCRIPT_DIR="$(dirname "$0")"
  VERIFY_ARGS=""
  
  if [ "$STRICT" = true ]; then
    VERIFY_ARGS="--strict"
  fi
  
  echo ""
  echo "Running localization verification..."
  "$SCRIPT_DIR/verify_locales.sh" $VERIFY_ARGS
fi
