TODO list:

# white the tar file on my drive, then do:
docker load -i buildkit_image.tar

docker tag moby/buildkit:buildx-stable-1 artifactory.iaf/labs-docker-dev/buildkit:buildx-stable-1

docker push artifactory.iaf/labs-docker-dev/buildkit:buildx-stable-1

then in docker buildx create add:
--driver-opt image=artifactory.iaf/labs-docker-dev/buildkit:buildx-stable-1 \


# white "docker-buildx" file from drive and upload to artifactory.
# then add to the beggining build_remote script:
echo "Setting up Docker Buildx plugin for this pod..."

mkdir -p ~/.docker/cli-plugins

wget -q http://artifactory.iaf/tools/docker-buildx -O ~/.docker/

cli-plugins/docker-buildx

chmod +x ~/.docker/cli-plugins/docker-buildx

docker buildx version


# on artifactory check if i can yum install:


1. On the Jenkins build machine:
    install the docker buildx plugin by:
    yum install docker-buildx-plugin
    then just check its alr by :
    docker buildx version
    * check if i have to white it.
    might have to do "export DOCKER_BUILDKIT=1" before docker build command.

2. Change the Dockerfile structure to match the one i made.

3. Make the .hcl file (similar to the one i made)

4. Modify the Jenkinsfile: add the required env vars,
    1. instead of the exports - use "environment" tag
        which is built in Jenkins and set them.
    2. change DockerbuildPush command to docker buildx bake --push
        do docker login in the bash script.
    3. create a script to connent to the remote server - the one i made.       






# remote server side:
# all the steps required to set the server up

1. get a working free server


2. install docker on it and set it up:
 * install docker:
    yum install docker

* make docker start even if the server restarts:
    sudo systemctl enable --now docker

* give permissions by this command:
    sudo usermod -aG docker $USER
    after that command, exit and connect again.

* clear temp files at 3AM everyday cronjob:    
    0 3 * * * docker system prune -a --volumes -f --filter "until=24h"



3. SSH setup. creates the SSH keys and set it to authorized keys:

    sudo systemctl enable ssh\sshd

    service ssh start

    mkdir -p ~/.ssh

    chmod 700 ~/.ssh

    rm -f ~/.ssh/id_ed25519*

    ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519

    cat ~/.ssh/id_ed25519.pub >> ~/.ssh/authorized_keys

    chmod 600 ~/.ssh/authorized_keys

    * then just uplaod to Vault the private ssh key: 
    cat ~/.ssh/id_ed25519
    and the host key: cat /etc/ssh/ssh_host_ed25519_key.pub

thats it! the remote server is ready!

if i wanna clean packages cache:
docker buildx prune --force --filter type=exec.cachemount