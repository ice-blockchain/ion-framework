#!/bin/bash

source "$(dirname "$0")/utils.sh"

# https://docs.flutter.dev/ui/accessibility-and-localization/internationalization
use_asdf flutter gen-l10n

# Run verification always
# Default values
UNTRANSLATED_FILE="untranslated_messages.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Localization Verification ===${NC}"

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo -e "${YELLOW}Warning: jq is required to parse the untranslated messages file${NC}"
  echo "Please install jq:"
  echo "  macOS: brew install jq"
  echo "  Linux: apt-get install jq"
  exit 1
fi

# Check if the untranslated messages file exists
if [ ! -f "$UNTRANSLATED_FILE" ]; then
  echo -e "${YELLOW}Warning: $UNTRANSLATED_FILE not found${NC}"
  exit 1
fi

# Check if file is empty or contains empty JSON (all translations complete)
if [ ! -s "$UNTRANSLATED_FILE" ] || [ "$(jq 'length' "$UNTRANSLATED_FILE" 2>/dev/null)" == "0" ]; then
  echo -e "${GREEN}✅ All translations are complete!${NC}"
  exit 0
else
  echo -e "${YELLOW}⚠️  Some translations are incomplete${NC}"
  echo "Check $UNTRANSLATED_FILE for details"
  exit 1
fi

exit 0
