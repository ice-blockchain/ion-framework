#!/bin/bash

source "$(dirname "$0")/utils.sh"

# https://pub.dev/packages/flutter_gen
# https://pub.dev/packages/freezed
# https://pub.dev/packages/json_serializable
# https://pub.dev/packages/widgetbook
use_asdf dart run build_runner clean
use_asdf dart run build_runner build --delete-conflicting-outputs

