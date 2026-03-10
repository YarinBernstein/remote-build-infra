# Can be used to test local builds
REGISTRY ?= artifactory.iaf/labs-docker-dev
SERVICE ?= simulation

build-slim:
	REGISTRY=$(REGISTRY) SERVICE=$(SERVICE) docker buildx bake --builder default slim

build-full:
	REGISTRY=$(REGISTRY) SERVICE=$(SERVICE) docker buildx bake --builder default full

clean-cache:
	REGISTRY=$(REGISTRY) SERVICE=$(SERVICE) docker buildx prune --builder default --force --filter type=exec.cachemount