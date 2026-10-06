#!/bin/bash

set -o errexit

REG_NAME='kind-registry'
REG_PORT='5001'

# Create registry if it doesn't exist
if [ "$(docker inspect -f '{{.State.Running}}' "${REG_NAME}" 2>/dev/null || true)" != 'true' ]; then
    docker run \
        -d \
        --restart=always \
        -p "${REG_PORT}:5000" \
        --name "${REG_NAME}" \
        registry:3
fi

# Create kind cluster
cat <<EOF | kind create cluster --name platform --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4

nodes:
  - role: control-plane
  - role: worker

containerdConfigPatches:
  - |-
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${REG_PORT}"]
      endpoint = ["http://${REG_NAME}:5000"]
EOF

# Connect registry to kind network
docker network connect "kind" "${REG_NAME}" || true

# Tell Kubernetes about the registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "localhost:${REG_PORT}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF
