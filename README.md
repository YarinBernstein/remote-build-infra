# Remote Build Pipeline for C++ Applications

## 🎯 The Goal: Decrease Build Times
This project solves the problem of slow build procceses in CI environments. Instead of running multiple, sequential `docker build` commands that compile the same C++ code repeatedly, and installs the same libraries or packages, this infrastructure uses **Docker Buildx Bake** to offload the heavy lifting to a Dedicated remote server. 

By sharing compilation stages, building targets concurrently, and utilizing aggressive caching, it completely eliminates double-building and saves precious CI execution time.

## 📂 File Structure

* **`docker-bake.hcl`**: The configuration file that defines multiple build targets (e.g., Slim for production, Full for dev) so they can be built concurrently.
* **`Dockerfile`**: A multi-stage setup (Base -> Builder -> Slim -> Full) that compiles the C++ code once and extracts only the final lightweight binary.
* **`build_remote.sh`**: The core automation script. It bootstrap the SSH connection, set up the remote BuildKit engine, and execute the bake command.
* **`buildkitd.toml`**: Configures the remote BuildKit daemon, enforcing strict Garbage Collection (GC) so the remote server's disk doesn't fill up with cache.
* **`Makefile`**: A clean wrapper to inject environment variables and trigger the pipeline easily. `make build-slim` / `make build-full` run local test builds; `make remote-build` / `make remote-push` run `build_remote.sh` (the latter also pushes to the registry). Requires `REMOTE_SECRET_SSH_KEY` to be set in the environment.
* **`main.cpp`**: The sample C++ application source code being compiled.
* **`.gitignore` & `.dockerignore`**: Ensures sensitive SSH keys, local artifacts, and heavy binaries are kept out of Git and the Docker build context.

## 🏗️ Architecture Overview

1. **The Client (CI Agent):** It prepares credentials and variables but does zero compilation.
2. **The Secure Tunnel:** Establishes a zero-touch SSH connection to the build server, bypassing manual host verification prompts.
3. **The Remote Builder:** A multi-core server running `moby/buildkit`. It receives the code, utilizes `RUN --mount=type=cache` for ultra-fast package downloads, and performs the heavy C++ compilation.
4. **Direct Push:** Instead of sending the heavy final images back to the weak CI agent (which takes a lot of time), the remote builder pushes them directly to the target container registry in seconds.