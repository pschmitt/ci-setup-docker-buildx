# Docker buildx setup for CI

## Usage

```bash
curl -fsSL https://raw.githubusercontent.com/pschmitt/ci-setup-docker-buildx/master/setup.sh | bash
```

## Examples

### GitHub Actions

```yaml
name: GitHub Actions CI

on:
  push:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repo
        uses: actions/checkout@master
        with:
          ref: ${{ github.ref }}

      - name: Install latest Docker X version
        run: curl -fsSL https://raw.githubusercontent.com/pschmitt/ci-setup-docker-buildx/master/setup.sh | bash

      - name: Docker login
        uses: azure/docker-login@v1
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build
        run: docker buildx build XXX
```

### Travis CI

```yaml
language: minimal
sudo: required
services:
  - docker
packages:
  - jq
before_install:
  # Install docker buildx
  - curl -fsSL https://raw.githubusercontent.com/pschmitt/ci-setup-docker-buildx/master/setup.sh | bash
script:
  - docker login -u "$DOCKER_USERNAME" -p "$DOCKER_PASSWORD"
  - docker buildx build XXX
```
