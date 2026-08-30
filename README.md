# Remote Build Pipeline for C++ Applications

## 🎯 The Goal: Decrease Build Times
This project solves the problem of slow build procceses in CI environments. Instead of running multiple, sequential `docker build` commands that compile the same C++ code repeatedly, and installs the same libraries or packages, this infrastructure uses **Docker Buildx Bake** to offload the heavy lifting to a Dedicated remote server. 

By sharing compilation stages, building targets concurrently, and utilizing aggressive caching, it completely eliminates double-building and saves precious CI execution time.

## 📂 File Structure

* **`docker-bake.hcl`**: The configuration file that defines multiple build targets (e.g., Slim for production, Full for dev) so they can be built concurrently.
* **`Dockerfile`**: A multi-stage setup (Base -> Builder -> Slim -> Full) that compiles the C++ code once and extracts only the final lightweight binary.
* **`build_remote.sh`**: The core automation script. It bootstrap the SSH connection, set up the remote BuildKit engine, and execute the bake command.
* **`buildkitd.toml`**: Configures the remote BuildKit daemon, enforcing strict Garbage Collection (GC) so the remote server's disk doesn't fill up with cache.
* **`Makefile`**: A clean wrapper to inject environment variables and trigger the pipeline easily. `make build-slim` / `make build-full` run local test builds; `make remote-build` / `make remote-push` run `build_remote.sh` (the latter also pushes to the registry). Requires `REMOTE_SECRET_SSH_KEY` and `REMOTE_HOST` to be set in the environment.
* **`main.cpp`**: The sample C++ application source code being compiled.
* **`setup_remote_server.sh`**: Run once on a fresh build server (an Oracle Cloud Always Free VM works well) to install Docker, open SSH, schedule cache cleanup, and generate the CI SSH keypair.
* **`.gitignore` & `.dockerignore`**: Ensures sensitive SSH keys, local artifacts, and heavy binaries are kept out of Git and the Docker build context.

## 🏗️ Architecture Overview

1. **The Client (CI Agent):** It prepares credentials and variables but does zero compilation.
2. **The Secure Connection:** Establishes a zero-touch SSH connection directly to the build server (IP/hostname from `REMOTE_HOST`), bypassing manual host verification prompts.
3. **The Remote Builder:** A multi-core server running `moby/buildkit`. It receives the code, utilizes `RUN --mount=type=cache` for ultra-fast package downloads, and performs the heavy C++ compilation.
4. **Direct Push:** Instead of sending the heavy final images back to the weak CI agent (which takes a lot of time), the remote builder pushes them directly to the target container registry in seconds.

## 🖥️ Setting up a remote build server

1. Provision a server with SSH access (e.g. an Oracle Cloud Always Free `VM.Standard.A1.Flex` instance running Oracle Linux 9 — free forever, no tunnel service needed since it gets a real public IP).
2. SSH in and run `bash setup_remote_server.sh` to install Docker, open port 22, schedule daily cache cleanup, and generate a dedicated SSH keypair for CI.
3. Store the printed private key as `REMOTE_SECRET_SSH_KEY` and the printed host public key as `REMOTE_HOST_KEY` in your CI secrets store (Vault) — never commit them.
4. Export `REMOTE_HOST` (and `REMOTE_USER`/`REMOTE_PORT` if not using the defaults `opc`/`22`) before running `build_remote.sh` or the `make remote-*` targets.