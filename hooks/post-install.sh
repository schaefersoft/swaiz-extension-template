#!/usr/bin/env bash
# example — the script behind `hooks.register` (phase postInstall) in
# extension.yaml: runs once, on first install of a version, ON THE HOST.
#
# Most extensions ship NO hooks: models, databases, secrets, services, routing,
# jobs and n8n provisioning are all declarative manifest fields aictl executes —
# and anything that runs INSIDE a container belongs in a job, not here. Use a
# hook ONLY for the truly imperative on the server itself (register with a
# third-party API, generate a one-time credential, a backfill that depends on
# runtime state).
#
# Phases: preInstall/postInstall (first install of a version), preUpdate/postUpdate
# (version change), preUninstall/postUninstall (remove). The script runs on the
# host with the bundle dir as cwd and an AICTL_* environment:
#
#   AICTL_HOOK (the phase), AICTL_EXTENSION_NAME, AICTL_EXTENSION_VERSION,
#   AICTL_EXTENSION_LIST, AICTL_PREVIOUS_VERSION, AICTL_UPDATE_DIRECTION,
#   AICTL_BUNDLE_DIR, AICTL_CONFIG_DIR, AICTL_DATA_DIR, AICTL_COMPOSE_FILE,
#   AICTL_ENV_FILE, AICTL_COMPOSE_PROJECT, AICTL_POSTGRES_USER, AICTL_BIN
set -euo pipefail

echo "[example] ${AICTL_HOOK} hook for ${AICTL_EXTENSION_NAME}@${AICTL_EXTENSION_VERSION}"
# (Nothing to do here — this is where a call to a vendor portal would go.)
echo "[example] ${AICTL_HOOK} hook done"
