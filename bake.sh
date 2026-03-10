# Supposed to replace the Jenkinsfile just for this expamle

# Here instead of the exports - I'll use "environment" tag
# which is built in Jenkins and set them.
export REGISTRY="artifactory.iaf/labs-docker-dev"
export SERVICE="simulation"

# This command will replace "DockerBuildPush" command in 
# Jenkins. Just replace --load with --push.
docker buildx bake --load