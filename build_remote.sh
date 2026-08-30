#!/bin/bash

# stop if any error occurs
set -e

# decides if push to artifactory or not
# empty BAKE_ACTION variable won't push
export ACTION="${BAKE_ACTION:-}"

# registry & service names
export REGISTRY="artifactory.iaf/labs-docker-dev"
export SERVICE="simulation"

# Remote build server connection - override via env vars (see
# setup_remote_server.sh for provisioning an Oracle Cloud Always Free VM).
# Defaults assume a direct connection to an Oracle Linux VM on port 22 -
# no tunnel service required.
export REMOTE_USER="${REMOTE_USER:-opc}"
export REMOTE_HOST="${REMOTE_HOST:?ERROR: REMOTE_HOST is not set. Export the build server's IP/hostname.}"
export REMOTE_PORT="${REMOTE_PORT:-22}"

# Set a builder name
export BUILDER_NAME="labs-builder"

# make sure that buildkitd configuration file exists
if [ ! -f "./buildkitd.toml" ]; then
    echo "ERROR: buildkitd.toml not found in the current directory. Aborting."
    exit 1
fi

# cleanup function to delete local secrets and configs
cleanup() {
    echo "Cleaning up local temporary files and SSH key..."
    rm -f ~/.ssh/id_ed25519 ~/.ssh/config ~/.ssh/known_hosts > /dev/null 2>&1 || true
}
# always run this func on exit
trap cleanup EXIT

# SSH setup
echo "Setting up SSH authentication..."

# REMOTE_SECRET_SSH_KEY must be provided by the environment (e.g. injected
# from Vault/CI secrets store). It is never hardcoded here.
if [ -z "${REMOTE_SECRET_SSH_KEY:-}" ]; then
    echo "ERROR: REMOTE_SECRET_SSH_KEY is not set. Export it from your secrets store before running this script."
    exit 1
fi

# Create the .ssh directory
mkdir -p ~/.ssh
chmod 700 ~/.ssh

echo "$REMOTE_SECRET_SSH_KEY" | tr -d '\r' > ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519

# Avoid ssh validation prompt (yes/no). REMOTE_HOST_KEY is the build
# server's public host key, printed by setup_remote_server.sh - store it
# alongside REMOTE_SECRET_SSH_KEY in your secrets store.
if [ -z "${REMOTE_HOST_KEY:-}" ]; then
    echo "ERROR: REMOTE_HOST_KEY is not set. Export the build server's public host key (see setup_remote_server.sh output)."
    exit 1
fi
export REMOTE_HOST_PUB_KEY="[${REMOTE_HOST}]:${REMOTE_PORT} ${REMOTE_HOST_KEY}"
echo "$REMOTE_HOST_PUB_KEY" > ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts

cat <<EOF > ~/.ssh/config
Host *
    StrictHostKeyChecking yes
    BatchMode yes
EOF
chmod 600 ~/.ssh/config


# buildx setup
echo "Setting up remote builder on ${REMOTE_HOST}:${REMOTE_PORT}..."

echo "Applying Docker Desktop WSL workaround on remote host..."
ssh -p ${REMOTE_PORT} ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p /usr/lib/wsl"

# check if builder exists - if it is , reuse it
if ! docker buildx inspect ${BUILDER_NAME} > /dev/null 2>&1; then
    echo "Creating a Builder '${BUILDER_NAME}'"
    docker buildx create \
        --name ${BUILDER_NAME} \
        --driver docker-container \
        --config ./buildkitd.toml \
        --use \
        ssh://${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PORT}
else
    echo "Builder '${BUILDER_NAME}' already exists. Reusing it"
    docker buildx use ${BUILDER_NAME}
fi

# check if connection is possible
echo "Bootstrapping remote connection..."
docker buildx inspect --bootstrap

# the build action
echo "Starting Buildx Bake process with action: '${ACTION}'..."
docker buildx bake --progress=plain ${ACTION}

echo "Build completed successfully!"