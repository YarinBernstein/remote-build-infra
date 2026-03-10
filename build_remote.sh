#!/bin/bash

# stop if any error occurs
set -e

# decides if push to artifactory or not
# empty BAKE_ACTION variable won't push
export ACTION="${BAKE_ACTION:-}"

# registry & service names
export REGISTRY="artifactory.iaf/labs-docker-dev"
export SERVICE="simulation"

# remote build server IP and port - pull from vault
# IMPORTANT - when i do it on mamdas i can remove the port part from this code
export REMOTE_USER="root"
export REMOTE_HOST="nbpdz-74-220-28-175.a.free.pinggy.link"
export REMOTE_PORT="33681"

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

# Create the .ssh directory
mkdir -p ~/.ssh
chmod 700 ~/.ssh

export REMOTE_SECRET_SSH_KEY="-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACA8nNJ00OdvGZHueYuZlnTNo8rFEzRIV0laWZS/e8S+3AAAAJCJM6CSiTOg
kgAAAAtzc2gtZWQyNTUxOQAAACA8nNJ00OdvGZHueYuZlnTNo8rFEzRIV0laWZS/e8S+3A
AAAEBgtcd3kqdrfFndiBsgzVWJft7+w2/+RsDvYbfBC5R+3Tyc0nTQ528Zke55i5mWdM2j
ysUTNEhXSVpZlL97xL7cAAAAC3Jvb3RAdWJ1bnR1AQI=
-----END OPENSSH PRIVATE KEY-----"

echo "$REMOTE_SECRET_SSH_KEY" | tr -d '\r' > ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519

# Avoid ssh validation prompt (yes/no)
export HOST_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEeX73JtLjQSr9SYdyEn3/vxoYp0GxnKoow2V3P0Yb9s root@vm2"
export REMOTE_HOST_PUB_KEY="[${REMOTE_HOST}]:${REMOTE_PORT} ${HOST_KEY}"
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