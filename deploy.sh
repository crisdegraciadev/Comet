DOCKER_USER=crisdegraciadev
IMAGE_NAME=comet
TAG=latest

docker build --no-cache -t $IMAGE_NAME . \
  && docker tag $IMAGE_NAME $DOCKER_USER/$IMAGE_NAME:$TAG \
  && docker push $DOCKER_USER/$IMAGE_NAME:$TAG
