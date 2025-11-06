#!/bin/bash

# --- Function to merge two env files: base and modifier ---
merge_app_env() {
    base_env=".app.env"
    modifier="$1"
    modifier_env=".$modifier.app.env"
    output_env=".merged$modifier_env"

    if [ ! -f "$modifier_env" ]; then
        echo "Modifier env file '$modifier_env' does not exist. Using $base_env as is for $output_env."
        cp "$base_env" "$output_env"
        return
    fi

    # Merge: lines from modifier override base
    # First, copy base_env to output_env
    cp "$base_env" "$output_env"
    # Then, for each key in modifier, override/add in output_env
    grep -v '^\s*$' "$modifier_env" | while IFS= read -r line; do
        key=$(echo "$line" | cut -d= -f1)
        value=$(echo "$line" | cut -d= -f2-)
        if grep -q "^$key=" "$output_env"; then
            # Replace existing key
            sed -i '' "s|^$key=.*|$key=$value|" "$output_env"
        else
            # Add new key
            echo "$key=$value" >> "$output_env"
        fi
    done
    echo "Merged $base_env and $modifier_env into $output_env"
}

# --- Function to generate iOS Swift config file ---
generate_ios_extension_config() {
    
    EXTENSION_CONFIG_DIR="ios/NotificationServiceExtension/Configuration"
    EXTENSION_CONFIG_FILE="$EXTENSION_CONFIG_DIR/Environment.swift"

    mkdir -p "$EXTENSION_CONFIG_DIR"

    cat > "$EXTENSION_CONFIG_FILE" << EOF
// SPDX-License-Identifier: ice License 1.0
// Auto-generated file from configure_env.sh - DO NOT EDIT MANUALLY

enum Environment {
    static let ionOrigin = "$(grep '^ION_ORIGIN=' .app.env | cut -d= -f2-)"
    static let pushTranslationsCacheMinutes = $(grep '^GENERIC_CONFIG_CACHE_MINUTES=' .app.env | cut -d= -f2-)
}
EOF

    echo "Generated iOS notification service extension configuration at $EXTENSION_CONFIG_FILE"
}

# --- Main Script Starts Here ---

environment="$1"

if [ -z "$environment" ]; then
    echo "Please pass environment as argument (staging / production / testnet)"
    exit 1
elif [[ "$environment" != "production" && "$environment" != "staging" && "$environment" != "testnet" ]]; then
    echo "Please pass a valid environment (staging / production / testnet)"
    exit 1
fi

# Copy secrets
cp -rf "../flutter-app-secrets/$environment/"* ./
cp -a "../flutter-app-secrets/$environment/" ./

# Merge store env files
merge_app_env "store"

# Generate iOS config
generate_ios_extension_config

# Load variables
source .env

echo "Done!"