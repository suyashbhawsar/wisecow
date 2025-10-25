# Cow wisdom web server

## Prerequisites

```
sudo apt install fortune-mod cowsay -y
```

## How to use?

1. Run `./wisecow.sh`
2. Point the browser to server port (default 4499)

## What to expect?
![wisecow](https://github.com/nyrahul/wisecow/assets/9133227/8d6bfde3-4a5a-480e-8d55-3fef60300d98)

# Problem Statement
Deploy the wisecow application as a k8s app

## Requirement
1. Create Dockerfile for the image and corresponding k8s manifest to deploy in k8s env. The wisecow service should be exposed as k8s service.
2. Github action for creating new image when changes are made to this repo
3. [Challenge goal]: Enable secure TLS communication for the wisecow app.

## Expected Artifacts
1. Github repo containing the app with corresponding dockerfile, k8s manifest, any other artifacts needed.
2. Github repo with corresponding github action.
3. Github repo should be kept private and the access should be enabled for following github IDs: nyrahul

## Docker Image Versioning

### Available Tags
Every commit creates:
- `sha-abc1234` (Recommended for K8s deployments)
- `latest` (Only for local testing, never use in production)

### Creating Versioned Releases
```bash
git tag v1.0.0
git push origin v1.0.0
```
Creates tags: `1.0.0`, `1.0`, `1`, `sha-abc1234`, `latest`

### Deployment Examples
```bash
# Use SHA tag (recommended)
kubectl set image deployment/wisecow wisecow=ghcr.io/suyashbhawsar/wisecow:sha-abc1234

# Use semantic version
kubectl set image deployment/wisecow wisecow=ghcr.io/suyashbhawsar/wisecow:1.0.0
```

### Get Current SHA
```bash
git rev-parse --short HEAD
```
