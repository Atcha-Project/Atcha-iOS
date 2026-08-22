#!/bin/sh
# Bootstraps the Tuist workspace.
#
# The four xcconfigs are gitignored (CI decodes the real ones from secrets into
# the repo root). Tuist fails generation when a referenced xcconfig is missing,
# so create empty stand-ins locally; empty files reproduce today's local
# behavior (settings not injected, build succeeds).
set -eu
cd "$(dirname "$0")/.."

for f in BaseConfig.xcconfig DevConfig.xcconfig StageConfig.xcconfig LiveConfig.xcconfig; do
  if [ ! -f "$f" ]; then
    printf '// local stand-in — real values are injected by CI (gitignored)\n' > "$f"
  fi
done

tuist install
tuist generate --no-open
