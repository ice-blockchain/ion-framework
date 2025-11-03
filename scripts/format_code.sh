#!/bin/bash

source "$(dirname "$0")/utils.sh"

CWD=$(pwd)
PACKAGES_RELATIVE_PATH="packages"
PACKAGES_DIR="$CWD/$PACKAGES_RELATIVE_PATH"

# Format function
format_package() {
    local PACKAGE_DIR="$1"
    local PACKAGE_NAME="$2"
    
    if [ ! -d "$PACKAGE_DIR" ]; then
        return 0
    fi
    
    echo "Formatting $PACKAGE_NAME"
    cd "$PACKAGE_DIR" || return 1
    
    FILES=$(find lib test -type f -name '*.dart' -not \( -path 'lib/generated*' -o -path 'lib/l10n*' \) -not \( -name '*.freezed.dart' -o -name '*.g.dart' \) 2>/dev/null)
    
    if [ -n "$FILES" ]; then
        use_asdf dart format --line-length=100 --set-exit-if-changed $FILES
        local FORMAT_EXIT_CODE=$?
        cd "$CWD" || return 1
        return $FORMAT_EXIT_CODE
    fi
    
    cd "$CWD" || return 1
    return 0
}

EXIT_CODE=0

# Format root package
echo "Formatting root package"
FILES=$(find lib test -type f -name '*.dart' -not \( -path 'lib/generated*' -o -path 'lib/l10n*' \) -not \( -name '*.freezed.dart' -o -name '*.g.dart' \) 2>/dev/null)
if [ -n "$FILES" ]; then
    use_asdf dart format --line-length=100 --set-exit-if-changed $FILES
    EXIT_CODE=$?
fi

# Format packages
if [ -d "$PACKAGES_DIR" ]; then
    for package_name in $(ls "$PACKAGES_DIR" 2>/dev/null); do
        # Skip example directories
        # if [[ "$package_name" == "example" ]]; then
        #     continue
        # fi
        
        PACKAGE_DIR="$PACKAGES_DIR/$package_name"
        
        # Only format if it's a directory and has lib or test folder
        if [ -d "$PACKAGE_DIR" ] && ([ -d "$PACKAGE_DIR/lib" ] || [ -d "$PACKAGE_DIR/test" ]); then
            format_package "$PACKAGE_DIR" "packages/$package_name"
            PACKAGE_EXIT_CODE=$?
            if [ $PACKAGE_EXIT_CODE -ne 0 ]; then
                EXIT_CODE=$PACKAGE_EXIT_CODE
            fi
        fi
    done
fi

exit $EXIT_CODE
