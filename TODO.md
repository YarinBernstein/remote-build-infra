# TODO

## If Jenkins can't reach public registries for the buildkit image

1. Write the buildkit image tar to disk, then:
   ```
   docker load -i buildkit_image.tar
   docker tag moby/buildkit:buildx-stable-1 artifactory.iaf/labs-docker-dev/buildkit:buildx-stable-1
   docker push artifactory.iaf/labs-docker-dev/buildkit:buildx-stable-1
   ```
2. In `docker buildx create`, add:
   ```
   --driver-opt image=artifactory.iaf/labs-docker-dev/buildkit:buildx-stable-1
   ```
3. Check whether `docker-buildx-plugin` is available via `yum install` from artifactory directly — if so, skip the manual upload below.

## If the docker-buildx CLI plugin isn't available via yum

1. Upload the `docker-buildx` binary to artifactory.
2. Add to the top of `build_remote.sh`:
   ```
   mkdir -p ~/.docker/cli-plugins
   wget -q http://artifactory.iaf/tools/docker-buildx -O ~/.docker/cli-plugins/docker-buildx
   chmod +x ~/.docker/cli-plugins/docker-buildx
   docker buildx version
   ```

## Jenkins integration (not yet done)

1. On the Jenkins build machine: `yum install docker-buildx-plugin`, then confirm with `docker buildx version`.
   May need `export DOCKER_BUILDKIT=1` before the `docker build` command.
2. Update the Jenkinsfile:
   - Replace the `export` lines with Jenkins' built-in `environment` block.
   - Change the docker build/push step to `docker buildx bake --push` (add `docker login` before it).
   - Call `build_remote.sh` to connect to the remote build server.

## Remote server setup

Done — `setup_remote_server.sh` automates Docker install, firewall, SSH keypair
generation, and the cache-cleanup cronjob. Provision a server (Oracle Cloud
Always Free works well) and run that script instead of doing this by hand.
