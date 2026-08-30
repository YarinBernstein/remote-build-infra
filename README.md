# Remote Build Pipeline for C++ Applications

## Goal

CI agents are usually weak and end up compiling the same C++ code and reinstalling the same packages on every run. This project uses **Docker Buildx Bake** to offload that work to a dedicated remote server instead — shared compilation stages, concurrent targets, and aggressive caching eliminate double-building and cut CI time.

## File structure

- `docker-bake.hcl` — defines the `slim` (production) and `full` (dev) build targets so they build concurrently.
- `Dockerfile` — multi-stage build (base → builder → slim/full) that compiles once and extracts only what each target needs.
- `build_remote.sh` — bootstraps the SSH connection to the build server, registers it as a Buildx builder, and runs the bake.
- `buildkitd.toml` — configures the remote BuildKit daemon's garbage collection so its disk doesn't fill up with cache.
- `setup_remote_server.sh` — run once on a fresh build server to install Docker, open SSH, schedule cache cleanup, and generate the CI SSH keypair.
- `Makefile` — shortcuts: `make build-slim` / `make build-full` for local test builds, `make remote-build` / `make remote-push` for the remote pipeline.
- `main.cpp` — sample C++ source being compiled.
- `.gitignore` / `.dockerignore` — keep SSH keys, local artifacts, and build output out of Git and the Docker build context.

## Architecture

1. **CI agent** — prepares credentials and variables, does zero compilation itself.
2. **SSH connection** — connects directly to the build server (`REMOTE_HOST`), with the host key pre-pinned so there's no interactive prompt.
3. **Remote builder** — a `moby/buildkit` server that receives the code, uses `RUN --mount=type=cache` for fast package installs, and does the actual compile.
4. **Direct push** — the remote builder pushes finished images straight to the registry, instead of sending them back through the weak CI agent.

## Setting up a remote build server

1. Provision a server with SSH access — an Oracle Cloud Always Free VM (Oracle Linux 9) works well and costs nothing.
2. SSH in and run `bash setup_remote_server.sh`. It installs Docker, opens port 22, schedules daily cache cleanup, and generates a dedicated SSH keypair for CI.
3. Store the printed private key as `REMOTE_SECRET_SSH_KEY` and the printed host public key as `REMOTE_HOST_KEY` in your CI secrets store — never commit them.
4. Export `REMOTE_HOST` (and `REMOTE_USER` / `REMOTE_PORT` if not using the defaults `opc` / `22`), then run `build_remote.sh` or `make remote-build` / `make remote-push`.
