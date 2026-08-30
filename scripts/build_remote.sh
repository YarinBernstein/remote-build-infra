#!/bin/bash
set -e

# Empty BAKE_ACTION won't push; set BAKE_ACTION=--push to push to the registry.
export ACTION="${BAKE_ACTION:-}"

export REGISTRY="artifactory.iaf/labs-docker-dev"
export SERVICE="simulation"

# Remote build server connection - override via env vars. Defaults assume a
# direct connection to an Oracle Linux VM on port 22 (see setup_remote_server.sh).
export REMOTE_USER="${REMOTE_USER:-opc}"
export REMOTE_HOST="${REMOTE_HOST:?ERROR: REMOTE_HOST is not set. Export the build server's IP/hostname.}"
export REMOTE_PORT="${REMOTE_PORT:-22}"

export BUILDER_NAME="labs-builder"

if [ ! -f "./docker/buildkitd.toml" ]; then
    echo "ERROR: docker/buildkitd.toml not found. Run this script from the repo root. Aborting."
    exit 1
fi

# Delete local secrets and SSH config on exit, success or failure
cleanup() {
    rm -f ~/.ssh/id_ed25519 ~/.ssh/config ~/.ssh/known_hosts > /dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Setting up SSH authentication..."

# REMOTE_SECRET_SSH_KEY and REMOTE_HOST_KEY must come from the environment
# (e.g. Vault/CI secrets) - never hardcode them here. Both are printed by
# setup_remote_server.sh when the build server is first provisioned.
if [ -z "${REMOTE_SECRET_SSH_KEY:-}" ]; then
    echo "ERROR: REMOTE_SECRET_SSH_KEY is not set. Export it from your secrets store before running this script."
    exit 1
fi
if [ -z "${REMOTE_HOST_KEY:-}" ]; then
    echo "ERROR: REMOTE_HOST_KEY is not set. Export the build server's public host key."
    exit 1
fi

mkdir -p ~/.ssh
chmod 700 ~/.ssh

echo "$REMOTE_SECRET_SSH_KEY" | tr -d '\r' > ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519

# Pin the host key so ssh never prompts to confirm it
echo "[${REMOTE_HOST}]:${REMOTE_PORT} ${REMOTE_HOST_KEY}" > ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts

cat <<EOF > ~/.ssh/config
Host *
    StrictHostKeyChecking yes
    BatchMode yes
EOF
chmod 600 ~/.ssh/config

echo "Setting up remote builder on ${REMOTE_HOST}:${REMOTE_PORT}..."

# Docker Desktop / WSL workaround: buildx expects this path to exist on the
# remote host when the client runs under WSL2, even though it's unused here.
ssh -p ${REMOTE_PORT} ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p /usr/lib/wsl"

if ! docker buildx inspect ${BUILDER_NAME} > /dev/null 2>&1; then
    echo "Creating builder '${BUILDER_NAME}'..."
    docker buildx create \
        --name ${BUILDER_NAME} \
        --driver docker-container \
        --config ./docker/buildkitd.toml \
        --use \
        ssh://${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PORT}
else
    echo "Reusing existing builder '${BUILDER_NAME}'..."
    docker buildx use ${BUILDER_NAME}
fi

echo "Bootstrapping remote connection..."
docker buildx inspect --bootstrap

echo "Starting Buildx Bake with action: '${ACTION}'..."
docker buildx bake -f docker/docker-bake.hcl --progress=plain ${ACTION}

echo "Build completed successfully!"
