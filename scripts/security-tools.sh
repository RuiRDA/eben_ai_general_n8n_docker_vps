#!/bin/sh
set -eu
# SHA-256 digests taken from the official release asset metadata on 2026-09-05.
mkdir -p .security-tools
curl --fail --silent --show-error --location https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_linux_x64.tar.gz -o .security-tools/gitleaks.tgz
printf '%s  %s\n' 551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb .security-tools/gitleaks.tgz | sha256sum --check --status
tar --no-same-owner -xzf .security-tools/gitleaks.tgz -C .security-tools gitleaks
curl --fail --silent --show-error --location https://github.com/aquasecurity/trivy/releases/download/v0.74.0/trivy_0.74.0_Linux-64bit.tar.gz -o .security-tools/trivy.tgz
printf '%s  %s\n' 2ae6fe3ee734b7fdf11335663e18c75ea12dccc76062f09f164a3b0f8be4371a .security-tools/trivy.tgz | sha256sum --check --status
tar --no-same-owner -xzf .security-tools/trivy.tgz -C .security-tools trivy
