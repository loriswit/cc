set -e

# check that environment variables are defined
if [[ -z "$INFO_V1_HTTP_USER" ]]; then echo "Error: variable 'INFO_V1_HTTP_USER' must be defined!"; exit 1; fi
if [[ -z "$INFO_V1_HTTP_PASS" ]]; then echo "Error: variable 'INFO_V1_HTTP_PASS' must be defined!"; exit 1; fi
if [[ -z "$INFO_V1_DB_HOST" ]]; then echo "Error: variable 'INFO_V1_DB_HOST' must be defined!"; exit 1; fi
if [[ -z "$INFO_V1_DB_PORT" ]]; then echo "Error: variable 'INFO_V1_DB_PORT' must be defined!"; exit 1; fi
if [[ -z "$INFO_V1_DB_DBNAME" ]]; then echo "Error: variable 'INFO_V1_DB_DBNAME' must be defined!"; exit 1; fi
if [[ -z "$INFO_V1_DB_USER" ]]; then echo "Error: variable 'INFO_V1_DB_USER' must be defined!"; exit 1; fi
if [[ -z "$INFO_V1_DB_PASS" ]]; then echo "Error: variable 'INFO_V1_DB_PASS' must be defined!"; exit 1; fi

# default values for Docker images
INFO_V1_IMAGE="${INFO_V1_IMAGE:-loriswit/watches-info-v1}"
IMAGE_V1_IMAGE="${IMAGE_V1_IMAGE:-loriswit/watches-image-v1}"

# push docker images
docker push "$INFO_V1_IMAGE"
docker push "$IMAGE_V1_IMAGE"

# create/update resources in cluster
envsubst < all.yml | kubectl apply -f -

# restart deployments to pull latest images
kubectl rollout restart deployment/info-v1
kubectl rollout restart deployment/image-v1
