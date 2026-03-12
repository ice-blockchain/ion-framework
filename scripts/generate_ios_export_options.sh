#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 --signType <EXPORT_METHOD> --bundleId <APP_ID> --outputPath <output_file>"
    exit 1
}

# Initialize variables
signType=""
bundleId=""
outputPath=""
method=""
profileType=""

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --signType) signType="$2"; shift ;;
        --bundleId) bundleId="$2"; shift ;;
        --outputPath) outputPath="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

# Check if all parameters are provided
if [[ -z "$signType" || -z "$bundleId" || -z "$outputPath" ]]; then
    usage
fi

# Set the method and profileType variables based on signType
case $signType in
    "adhoc")
        method="ad-hoc"
        profileType="AdHoc"
        ;;
    "appstore")
        method="app-store-connect"
        profileType="AppStore"
        ;;
    *) 
        echo "Invalid signType. Use 'adhoc' or 'appstore'." && exit 1 
        ;;
esac

# Generate the XML content
cat <<EOL > "$outputPath"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>method</key>
    <string>$method</string>
    <key>provisioningProfiles</key>
    <dict>
      <key>$bundleId</key>
      <string>match $profileType $bundleId</string>
      <key>$bundleId.NotificationServiceExtension</key>
      <string>match $profileType $bundleId.NotificationServiceExtension</string>
      <key>$bundleId.ShareExtension</key>
      <string>match $profileType $bundleId.ShareExtension</string>
    </dict>
  </dict>
</plist>
EOL

echo "Generated plist file at: $outputPath"