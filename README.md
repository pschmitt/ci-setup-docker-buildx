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
  # Update docker
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  - sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  - sudo apt-get update
  - sudo apt-get -y -o Dpkg::Options::="--force-confnew" install docker-ce
  # Install docker buildx
  - curl -L https://raw.githubusercontent.com/pschmitt/ci-setup-docker-buildx/master/setup.sh | bash
script:
  - echo '{"experimental":true}' | sudo tee /etc/docker/daemon.json
  - sudo service docker restart
  - docker login -u "$DOCKER_USERNAME" -p "$DOCKER_PASSWORD"
  - ./build.sh
```
