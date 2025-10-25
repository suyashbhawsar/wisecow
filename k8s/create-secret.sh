#!/bin/bash

# Helper script to create GHCR secret for Kubernetes
# Usage: ./create-secret.sh <GITHUB_USERNAME> <GITHUB_PAT> <EMAIL>

set -e

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <GITHUB_USERNAME> <GITHUB_PAT> <EMAIL>"
    echo "Example: $0 suyashbhawsar ghp_xxxxx sqjbt@qacmjeq.com"
    exit 1
fi

GITHUB_USERNAME=$1
GITHUB_PAT=$2
EMAIL=$3

echo "Creating GHCR secret for Kubernetes..."

# Create the Docker config JSON
DOCKER_CONFIG=$(echo -n "{\"auths\":{\"ghcr.io\":{\"username\":\"$GITHUB_USERNAME\",\"password\":\"$GITHUB_PAT\",\"email\":\"$EMAIL\",\"auth\":\"$(echo -n "$GITHUB_USERNAME:$GITHUB_PAT" | base64)\"}}}" | base64)

# Replace placeholder in ghcr-secret.yaml
sed "s/DOCKER_CONFIG_JSON_BASE64/$DOCKER_CONFIG/" ghcr-secret.yaml > ghcr-secret-generated.yaml

echo "Secret created in ghcr-secret-generated.yaml"
echo "Apply it using: kubectl apply -f ghcr-secret-generated.yaml"
