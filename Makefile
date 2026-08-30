# Can be used to test local builds
REGISTRY ?= artifactory.iaf/labs-docker-dev
SERVICE ?= simulation

build-slim:
	REGISTRY=$(REGISTRY) SERVICE=$(SERVICE) docker buildx bake --builder default slim

build-full:
	REGISTRY=$(REGISTRY) SERVICE=$(SERVICE) docker buildx bake --builder default full

clean-cache:
	REGISTRY=$(REGISTRY) SERVICE=$(SERVICE) docker buildx prune --builder default --force --filter type=exec.cachemount

# Remote build pipeline (build_remote.sh). Requires REMOTE_SECRET_SSH_KEY
# to be set in the environment (from Vault/CI secrets).
remote-build:
	./build_remote.sh

remote-push:
	BAKE_ACTION=--push ./build_remote.sh