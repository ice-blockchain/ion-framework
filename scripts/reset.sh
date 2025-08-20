#!/bin/bash

source "$(dirname "$0")/utils.sh"

echo "🧹 Cleaning Flutter project..."
use_asdf flutter clean

echo "🚀 Running bootstrap..."
./scripts/bootstrap.sh

echo "📦 Getting dependencies..."
melos pub_get

echo "🔧 Generating code..."
melos generate

echo "✅ Reset complete!"
