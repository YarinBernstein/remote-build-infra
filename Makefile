# Can be used to test local builds
REGISTRY ?= artifactory.iaf/labs-docker-dev
SERVICE ?= simulation

build-slim:
	REGISTRY=$(REGISTRY) SERVICE=$(SERVICE) docker buildx bake -f docker/docker-bake.hcl --builder default slim

build-full:
	REGISTRY=$(REGISTRY) SERVICE=$(SERVICE) docker buildx bake -f docker/docker-bake.hcl --builder default full

clean-cache:
	REGISTRY=$(REGISTRY) SERVICE=$(SERVICE) docker buildx prune --builder default --force --filter type=exec.cachemount

# Remote build pipeline (scripts/build_remote.sh). Requires REMOTE_HOST,
# REMOTE_SECRET_SSH_KEY and REMOTE_HOST_KEY to be set in the environment
# (see scripts/setup_remote_server.sh).
remote-build:
	./scripts/build_remote.sh

remote-push:
	BAKE_ACTION=--push ./scripts/build_remote.sh