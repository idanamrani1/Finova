#!/usr/bin/env bash
#
# Deploys the Finova frontend: build -> analyze -> test -> back up the live
# directory -> copy -> fix ownership -> verify the new build actually
# answers over HTTPS.
#
# Written after a manual "build, cp, chown" sequence was repeated by hand
# several times in one session and nearly shipped a stale build once (the
# cp step was run before the build finished). This script makes each of
# those steps unskippable and unordered-proof: it stops at the first
# failure instead of silently continuing with a half-deployed state.
#
# Usage:
#   ./deploy.sh              # build + deploy
#   ./deploy.sh --skip-tests # build + deploy, skip flutter test (fast path)
#   ./deploy.sh --check-only # build + analyze + test, no deploy
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

FLUTTER_BIN="$HOME/flutter/bin"
export PATH="$FLUTTER_BIN:$PATH"

WEB_ROOT="/var/www/finova"
BACKUP_ROOT="/var/www/finova.bak-$(date +%Y%m%d-%H%M%S)"
HEALTH_URL="https://finovam.ddns.net/"

SKIP_TESTS=false
CHECK_ONLY=false
for arg in "$@"; do
  case "$arg" in
    --skip-tests) SKIP_TESTS=true ;;
    --check-only) CHECK_ONLY=true ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Usage: $0 [--skip-tests] [--check-only]" >&2
      exit 1
      ;;
  esac
done

step() { printf '\n\033[1;36m==> %s\033[0m\n' "$1"; }
ok()   { printf '\033[1;32m✓ %s\033[0m\n' "$1"; }
fail() { printf '\033[1;31m✗ %s\033[0m\n' "$1" >&2; exit 1; }

command -v flutter >/dev/null 2>&1 || fail "flutter not found at $FLUTTER_BIN — check the PATH in this script"

step "flutter analyze"
if ! flutter analyze --no-pub 2>&1 | tee /tmp/finova-analyze.log | grep -qE '^\s*error'; then
  ok "no analyzer errors"
else
  grep -E '^\s*error' /tmp/finova-analyze.log
  fail "analyzer found errors — fix them before deploying"
fi

if [ "$SKIP_TESTS" = false ]; then
  step "flutter test"
  flutter test || fail "tests failed — fix them before deploying, or rerun with --skip-tests if you're sure"
  ok "all tests passed"
else
  step "flutter test (skipped via --skip-tests)"
fi

step "flutter build web --release"
flutter build web --release || fail "build failed"
ok "build produced build/web"

# Sanity-check the build actually contains something before we touch prod —
# an empty or half-written build/web directory would otherwise happily
# overwrite a working site with nothing.
[ -f build/web/main.dart.js ] || fail "build/web/main.dart.js missing — build looks incomplete, aborting before touching $WEB_ROOT"
BUILD_SIZE=$(du -sh build/web | cut -f1)
ok "build/web is $BUILD_SIZE"

if [ "$CHECK_ONLY" = true ]; then
  step "check-only mode — stopping before deploy"
  exit 0
fi

step "backing up current live build"
if [ -d "$WEB_ROOT" ]; then
  sudo cp -a "$WEB_ROOT" "$BACKUP_ROOT"
  ok "backed up to $BACKUP_ROOT"
else
  echo "  (no existing $WEB_ROOT to back up — first deploy?)"
fi

step "copying new build to $WEB_ROOT"
sudo cp -r build/web/* "$WEB_ROOT"/
sudo chown -R www-data:www-data "$WEB_ROOT"
ok "copied and chowned"

step "verifying the deployed site responds"
# main.dart.js must stay no-cache (it isn't content-hashed by Flutter's web
# build, so long caching here is what caused the "I don't see the update on
# mobile" bug once already) — checked here so a regressed nginx config is
# caught at deploy time instead of by a confused user days later.
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' -m 20 "$HEALTH_URL" || echo "000")
[ "$HTTP_CODE" = "200" ] || fail "site returned HTTP $HTTP_CODE at $HEALTH_URL — check nginx and the service"
CACHE_HEADER=$(curl -sI -m 20 "${HEALTH_URL}main.dart.js" | grep -i '^cache-control' || true)
if echo "$CACHE_HEADER" | grep -qi 'immutable\|max-age=[1-9]'; then
  echo "  ⚠ main.dart.js Cache-Control looks long-lived: $CACHE_HEADER"
  echo "    This file is NOT content-hashed by Flutter — long caching means"
  echo "    users won't see this deploy. Check /etc/nginx/sites-available/finova."
else
  ok "main.dart.js Cache-Control looks safe: ${CACHE_HEADER:-<none>}"
fi
ok "site is live at $HEALTH_URL"

step "done"
echo "Backup of the previous build: $BACKUP_ROOT"
echo "Roll back with: sudo rm -rf $WEB_ROOT && sudo mv $BACKUP_ROOT $WEB_ROOT"
