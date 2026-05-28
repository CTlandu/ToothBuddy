#!/usr/bin/env bash
# Quality audit one-stop runner (Plan U7, docs/plans/2026-05-28-001-refactor-quality-audit-plan.md).
#
# Runs in order (each step is independent — switching working dirs between an
# xcodebuild and a `cd ToothBuddyCore && swift test` was racing the derived-data
# cache and intermittently failing the xcodebuild test step, so we run the pure
# Core suite first while the .xcodeproj derived-data is still fresh from prior runs):
#   1. xcodegen generate    refresh .xcodeproj from project.yml
#   2. swift test (Core)    ToothBuddyCore pure logic — no simulator needed
#   3. xcodebuild test      builds app + ToothBuddyTests (covers build + tests)
#   4. periphery scan       dead-code report (install: brew install peripheryapp/periphery/periphery)
#
# Each step short-circuits on failure with a clear exit code.
# Usage: bash scripts/audit.sh

set -euo pipefail

# Move to repo root so all subsequent paths are relative there.
cd "$(dirname "$0")/.."

DEST='platform=iOS Simulator,name=iPhone 16,OS=18.6'

heading() {
  printf '\n\033[1;36m== %s ==\033[0m\n' "$1"
}

heading "1/4 xcodegen generate"
xcodegen generate

heading "2/4 swift test (ToothBuddyCore — pure logic)"
(
  cd ToothBuddyCore
  swift test 2>&1 | grep -E "Executed [0-9]+ test|error:" | tail -2
)

heading "3/4 xcodebuild test (app build + warnings-as-errors + ToothBuddyTests)"
xcodebuild \
  -project ToothBuddy.xcodeproj \
  -scheme ToothBuddy \
  -destination "$DEST" \
  CODE_SIGNING_ALLOWED=NO \
  test 2>&1 | grep -E "Executed [0-9]+ test|FAIL|error:|\*\*" | tail -3

heading "4/4 periphery scan (dead code)"
if command -v periphery >/dev/null 2>&1; then
  periphery scan || {
    echo "Periphery reported issues — review and decide per-finding."
    exit 4
  }
else
  echo "Periphery not installed. Run:"
  echo "    brew install peripheryapp/periphery/periphery"
  echo "Then re-run this script. Skipping for now."
fi

heading "Done"
echo "All checks passed."
