#!/bin/zsh
# UI run on the iPhone 17 Pro 27.0 sim: ui.sh <label> <tag> <light|dark> <content-size> <Class[/test]> [...]
set -u
SP=${SP:-/tmp/lifeos-build}; mkdir -p "$SP"
UDID=0ACE7E5C-513C-4989-B110-F8A713BFD472
cd "/Users/ethan/[E] Claude Code/v1-GoogleAI-ADHDLifeOS/ADHDLifeOS"
label=$1; tag=$2; look=$3; size=$4; shift 4
only=()
for c in "$@"; do only+=("-only-testing:ADHD LifeOSUITests/$c"); done
xcrun simctl bootstatus $UDID -b > /dev/null 2>&1
xcrun simctl ui $UDID appearance $look
xcrun simctl ui $UDID content_size $size
rm -rf "$SP/$label.xcresult"
TEST_RUNNER_TODAY_RENDER_TAG=$tag xcodebuild test -project "ADHD LifeOS.xcodeproj" -scheme "ADHD LifeOS" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=27.0' \
  "${only[@]}" -enableCodeCoverage NO -resultBundlePath "$SP/$label.xcresult" > "$SP/$label.log" 2>&1
echo "XCODEBUILD_EXIT=$?" >> "$SP/$label.log"
