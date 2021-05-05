set -e

# push docker images
docker push loriswit/watches-info-v1
docker push loriswit/watches-image-v1

# create/update resources in cluster
kubectl apply -f all.yml
