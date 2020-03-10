#!/usr/bin/env bash

usage() {
  echo "$(basename "$0")"
}

update_docker() {
  if [[ "$TRAVIS" == "true" ]]
  then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get -y -o Dpkg::Options::="--force-confnew" install docker-ce
  elif [[ "$GITHUB_ACTIONS" == "true" ]]
  then
    curl -fsSL https://get.docker.com | bash
  fi
}

setup_docker() {
  # Append experimental: true to docker cli config
  local config=~/.docker/config.json
  if [[ -e "$config" ]]
  then
    if [[ "$(jq -r '.experimental?' "$config")" == "null" ]]
    then
      jq '. + {"experimental": "true"}' "$config" > "${config}.new"
      mv "${config}.new" "$config"
    fi
  else
    echo '{"experimental": "true"}' > "$config"
  fi
}

get_latest_buildx_version() {
  # Prefer local script
  if ! [[ -x ./git-latest-version.sh ]]
  then
    # Download
    curl -O -L https://raw.githubusercontent.com/pschmitt/ci-setup-docker-buildx/master/git-latest-version.sh
    chmod +x ./git-latest-version.sh
  fi
  ./git-latest-version.sh docker/buildx
}

install_latest_buildx() {
  local arch
  local buildx_path=~/.docker/cli-plugins/docker-buildx
  local version

  version="$(get_latest_buildx_version)"

  if [[ -x "$buildx_path" ]]
  then
    return
  fi

  case "$(uname -m)" in
    x86_64)
      arch=amd64
      ;;
    aarch64)
      arch=arm64
      ;;
    armv6l|arm)
      arch=arm-v6
      ;;
    armv7l|armhf)
      arch=arm-v7
      ;;
    *)
      arch="$(uname -m)"
      ;;
  esac
  mkdir -p "$(dirname "$buildx_path")"
  curl -L -o "$buildx_path" \
    "https://github.com/docker/buildx/releases/download/v${version}/buildx-v${version}.linux-${arch}"
  chmod +x "$buildx_path"
}

debug_info() {
  env
  docker version
  docker buildx ls
  docker buildx inspect
  ls -1 /proc/sys/fs/binfmt_misc
}

setup_buildx() {
  case "$(uname -m)" in
    x86_64|i386)
      docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
      # docker run --rm --privileged docker/binfmt:a7996909642ee92942dcd6cff44b9b95f08dad64
      ;;
  esac

  # CI
  if [[ "$GITHUB_ACTIONS" == "true" ]] || [[ "$TRAVIS" == "true" ]]
  then
    docker buildx create \
      --use \
      --name builder \
      --node builder \
      --driver docker-container \
      --driver-opt network=host
  fi
  docker buildx inspect --bootstrap

  # Debug info for buildx and multiarch support
  debug_info
}

echo "Starting docker buildx setup"
update_docker
setup_docker

# buildx setup
# export DOCKER_CLI_EXPERIMENTAL=enabled
# export PATH="${PATH}:~/.docker/cli-plugins"

if ! [[ -x ~/.docker/cli-plugins/docker-buildx ]]
then
  install_latest_buildx
  setup_buildx
fi

if ! docker buildx version >/dev/null
then
  echo "buildx is not available" >&2
  exit 99
fi

# vim set et ts=2 sw=2 :
