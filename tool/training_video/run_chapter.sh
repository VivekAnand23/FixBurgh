#!/bin/bash
# Runs one chapter of the training walkthrough on the iOS Simulator against
# the local emulators. Saves a screenshot at the end of each step to
# build/training_video/shots/<step>.png, logs when each step starts (for
# lining up the voice), and approves the provider application when asked.
#
#   tool/training_video/run_chapter.sh <a..g> [record] [fast]
#
# With "record", it also records the simulator to
# build/training_video/clips/<chapter>.mov. With "fast", the narration
# pauses are skipped (a rehearsal).
set -u
CH=$1; MODE=${2:-}; SPEED=${3:-}
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
OUT=$ROOT/build/training_video
SIM=${SIM:-$(xcrun simctl list devices booted | grep -oE '[0-9A-F-]{36}' | head -1)}
mkdir -p "$OUT/shots" "$OUT/clips" "$OUT/logs"
cd "$ROOT"
names=(a "chapter a" b "chapter b" c "chapter c" d "chapter d" e "chapter e" f "chapter f" g "chapter g")
FAST=false; [ "$SPEED" = fast ] && FAST=true
LOG=$OUT/logs/$CH.log
: > "$LOG"
if [ "$MODE" = record ]; then
  xcrun simctl io "$SIM" recordVideo --codec=h264 --force "$OUT/clips/$CH.mov" 2>/dev/null &
  REC=$!
  sleep 2
fi
T0=$(python3 -c 'import time; print(time.time())')
echo "RECSTART $T0" >> "$LOG"
flutter test integration_test/training_walkthrough_test.dart -d "$SIM" --flavor dev \
  --dart-define=USE_EMULATORS=true --dart-define=SCREENSHOTS=true --dart-define=SKIP_LOCATION=true \
  --dart-define=FEATURES=society,channels,services,monetisation \
  --dart-define=PHOTOS="$ROOT/tool/training_video/photos" --dart-define=FAST=$FAST \
  --plain-name "chapter $CH" 2>&1 |
while IFS= read -r line; do
  now=$(python3 -c 'import time; print(time.time())')
  case "$line" in
    *"STEP-END "*)
      id=$(echo "$line" | sed 's/.*STEP-END //' | tr -d '\r')
      echo "END $id $now" >> "$LOG"
      xcrun simctl io "$SIM" screenshot "$OUT/shots/$id.png" >/dev/null 2>&1
      echo ">> shot $id";;
    *"STEP "*)
      id=$(echo "$line" | sed 's/.*STEP //' | tr -d '\r')
      echo "START $id $now" >> "$LOG"
      echo ">> step $id";;
    *"FAILSHOT"*)
      xcrun simctl io "$SIM" screenshot "$OUT/fail-$CH.png" >/dev/null 2>&1
      echo ">> failure screenshot: $OUT/fail-$CH.png";;
    *"ACTION approve-provider "*)
      email=$(echo "$line" | sed 's/.*approve-provider //' | tr -d '\r')
      node tool/training_video/approve.mjs "$email";;
    *"All tests passed"*|*"Some tests failed"*|*"Timed out"*|*"Bad state"*|*"Expected:"*)
      echo "$line";;
  esac
done
if [ -n "${REC:-}" ]; then
  kill -INT "$REC"; wait "$REC" 2>/dev/null
fi
grep -q "END " "$LOG" && echo "chapter $CH: $(grep -c '^END ' "$LOG") steps"
