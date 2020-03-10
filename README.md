# Docker buildx setup for CI

## Usage

```bash
curl -L https://raw.githubusercontent.com/pschmitt/ci-setup-docker-buildx/master/setup.sh | bash
```

## Examples

### Travis CI

```yaml
language: minimal
sudo: required
services:
  - docker
before_install:
  # Install docker buildx
  - curl -L https://raw.githubusercontent.com/pschmitt/ci-setup-docker-buildx/master/setup.sh | bash
script:
  - docker login -u "$DOCKER_USERNAME" -p "$DOCKER_PASSWORD"
  - ./build.sh
```
