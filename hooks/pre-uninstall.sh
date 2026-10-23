#!/usr/bin/env bash
# example — the script behind `hooks.deregister` (phase preUninstall) in
# extension.yaml: runs on `aictl extension remove`, while the extension's
# services are still UP so it can reach them.
#
# Use it to cleanly deregister/flush before teardown. aictl already stops the
# extension's services, removes its route, purges its secrets and clears its
# state — so a hook is only needed for side effects aictl cannot know about.
set -euo pipefail

echo "[example] preUninstall hook for ${AICTL_EXTENSION_NAME}@${AICTL_EXTENSION_VERSION}"
echo "[example] preUninstall hook done"
