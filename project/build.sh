# default values for Docker images
INFO_V1_IMAGE="${INFO_V1_IMAGE:-loriswit/watches-info-v1}"
IMAGE_V1_IMAGE="${IMAGE_V1_IMAGE:-loriswit/watches-image-v1}"

docker build -t "$INFO_V1_IMAGE" info
docker build -t "$IMAGE_V1_IMAGE" image
