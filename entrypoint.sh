#!/usr/bin/env bash

set -euo pipefail

echo "Copying default config files to working directory $(pwd)…"
cp --recursive --no-clobber /kindof/etc /kindof/compose.yaml.tpl .

echo "Ensuring PKI and kubeconfigs…"
/kindof/bootstrap.sh

ls -lah

echo "Starting Docker…"
service docker start

tries=0
echo "Waiting for Docker to be running…"
until docker stats --no-stream > /dev/null 2>&1; do
  sleep 1
  if [[ $tries -eq 5 ]]; then
    echo "Timed out. Did you forget to run this container with --privileged?"
    exit 1
  fi
  tries=$((tries + 1))
done

echo "Docker is running."

# start control plane
echo "Starting kind of Kubernetes control plane…"
docker compose up -d etcd apiserver controller-manager

export KUBECONFIG=etc/kubeconfig

tries=0
echo "Waiting for apiserver…"
until kubectl get namespaces; do
  sleep 2
  if [[ $tries -eq 10 ]]; then
    echo "Timed out."
    exit 1
  fi
  tries=$((tries + 1))
done

if [ -d kube ]; then
  echo "Applying kube resources…"
  kubectl apply --filename kube --recursive
fi

# stream logs until we receive a signal
docker compose logs -f apiserver controller-manager

docker compose down
