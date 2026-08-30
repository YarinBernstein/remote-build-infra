# Remote Build Pipeline for C++ Applications

## Goal

CI agents are usually weak and end up compiling the same C++ code and reinstalling the same packages on every run. This project uses **Docker Buildx Bake** to offload that work to a dedicated remote server instead — shared compilation stages, concurrent targets, and aggressive caching eliminate double-building and cut CI time.

## File structure

```
.
├── Makefile              # shortcuts: build-slim/build-full (local), remote-build/remote-push
├── README.md
├── TODO.md
├── docker/
│   ├── Dockerfile        # multi-stage build (base → builder → slim/full)
│   ├── docker-bake.hcl   # defines the slim (production) and full (dev) targets
│   └── buildkitd.toml    # remote BuildKit daemon cache/garbage-collection config
├── scripts/
│   ├── build_remote.sh         # bootstraps the SSH connection, runs the bake
│   └── setup_remote_server.sh  # one-time setup for a fresh build server
└── src/
    └── main.cpp           # sample C++ source being compiled
```

`.gitignore` / `.dockerignore` keep SSH keys, local artifacts, and build output out of Git and the Docker build context.

## Architecture

1. **CI agent** — prepares credentials and variables, does zero compilation itself.
2. **SSH connection** — connects directly to the build server (`REMOTE_HOST`), with the host key pre-pinned so there's no interactive prompt.
3. **Remote builder** — a `moby/buildkit` server that receives the code, uses `RUN --mount=type=cache` for fast package installs, and does the actual compile.
4. **Direct push** — the remote builder pushes finished images straight to the registry, instead of sending them back through the weak CI agent.

## Setting up a remote build server

1. Provision a server with SSH access — an Oracle Cloud Always Free VM (Oracle Linux 9) works well and costs nothing.
2. SSH in and run `bash scripts/setup_remote_server.sh`. It installs Docker, opens port 22, schedules daily cache cleanup, and generates a dedicated SSH keypair for CI.
3. Store the printed private key as `REMOTE_SECRET_SSH_KEY` and the printed host public key as `REMOTE_HOST_KEY` in your CI secrets store — never commit them.
4. Export `REMOTE_HOST` (and `REMOTE_USER` / `REMOTE_PORT` if not using the defaults `opc` / `22`), then from the repo root run `make remote-build` / `make remote-push` (or `scripts/build_remote.sh` directly).
