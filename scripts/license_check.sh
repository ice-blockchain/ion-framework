touch files.cnt
(
    find . -type f -name "*.dart" ! -name "*.g.dart" ! -name "*.freezed.dart" ! -name "*.gen.dart" ! -path "*/.dart_tool/*" \( -path "./test/*" -o -path "./lib/*" \) ! -path "./lib/generated/*" &&
    find . -type f -name "*.dart"  ! -name "*.g.dart" ! -name "*.freezed.dart" ! -path "*/.dart_tool/*" \( -path "./packages/*/test/**" -o -path "./packages/*/lib/**" \)
) | xargs -0 $(dirname -- "$0")/license_add.sh
CNT_VALUE="$(wc -l < files.cnt |  tr -d ' \t\n\r' )"
if [ $((CNT_VALUE)) -gt 0 ]
then
echo "There were $CNT_VALUE file(s) without license:"
while IFS= read -r path; do echo "  - $path"; done < files.cnt
echo "Add the license header to the above file(s), then commit and push again."
rm -rf files.cnt
exit 1
fi
rm -rf files.cnt
