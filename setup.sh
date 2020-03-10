#!/usr/bin/env bash

usage() {
  echo "$(basename "$0")"
}

is_travis() {
  [[ "$TRAVIS" == "true" ]]
}

is_github_actions() {
  [[ "$GITHUB_ACTIONS" == "true" ]]
}

is_ci() {
  is_travis || is_github_actions
}

install_dependencies() {
  if is_ci
  then
    apt update
    apt install -y jq
  fi
}

update_docker() {
  if is_ci
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
      jq '. + {"experimental": "enabled"}' "$config" > "${config}.new"
      mv "${config}.new" "$config"
    fi
  else
    mkdir -p "$(dirname "$config")"
    echo '{"experimental": "enabled"}' > "$config"
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
  if is_ci
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
