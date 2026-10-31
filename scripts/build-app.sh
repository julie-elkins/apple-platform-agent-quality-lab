#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
build_configuration=${1:-debug}
app_directory="$project_root/dist/Apple Platform Agent Quality Lab.app"

case "$build_configuration" in
  debug)
    xcode_configuration=Debug
    ;;
  release)
    xcode_configuration=Release
    ;;
  *)
    printf '%s\n' "Unsupported configuration: $build_configuration" >&2
    exit 2
    ;;
esac

if command -v xcodebuild >/dev/null 2>&1 && [ -d "$project_root/AppleAgentQualityLab.xcodeproj" ]; then
  derived_data_directory="$project_root/DerivedData"
  xcodebuild \
    -project "$project_root/AppleAgentQualityLab.xcodeproj" \
    -scheme AppleAgentQualityLab \
    -configuration "$xcode_configuration" \
    -derivedDataPath "$derived_data_directory" \
    build \
    CODE_SIGNING_ALLOWED=NO

  built_app="$derived_data_directory/Build/Products/$xcode_configuration/Apple Platform Agent Quality Lab.app"
  rm -rf "$app_directory"
  ditto "$built_app" "$app_directory"
else
  binary_directory=$(swift build --package-path "$project_root" --configuration "$build_configuration" --show-bin-path)
  mkdir -p "$app_directory/Contents/MacOS"
  mkdir -p "$app_directory/Contents/Resources"
  cp "$binary_directory/apple-agent-quality-lab" "$app_directory/Contents/MacOS/apple-agent-quality-lab"
  cp "$project_root/AppResources/Info.plist" "$app_directory/Contents/Info.plist"
  chmod +x "$app_directory/Contents/MacOS/apple-agent-quality-lab"
fi

printf '%s\n' "$app_directory"
