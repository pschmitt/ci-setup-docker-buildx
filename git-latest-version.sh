#!/usr/bin/env bash

usage() {
  echo "Usage: $(basename "$0") REPO [RELEASE_CHANNEL]"
  echo "Examples:"
  echo "$(basename "$0") ansible"
  echo "$(basename "$0") neovim/neovim stable"
}

get_latest_release() {
  local repo="$1"
  local rel_chan="$2"
  local tags
  local rel_ref

  # if $1 is ansible -> use ansible/ansible
  if ! grep -qE "\w+/\w+" <<< "$repo"
  then
    repo="${repo}/${repo}"
  fi

  tags="$(git ls-remote --tags https://github.com/"${repo}")"

  if [[ -n "$rel_chan" ]]
  then
    rel_ref="$(awk '/refs\/tags\/'"${rel_chan}"'/ { print $1 }' <<< "$tags")"

    awk '/'"${rel_ref}"'/ {print $2}' <<< "$tags" | \
      sed -rn 's|.*refs/tags/v?([^\^]+)(\^\{\})?|\1|p' | \
      grep -Ev '^'"${rel_chan}"'$' | \
      tail -1
  else
    tail -1 <<< "$tags" | sed -rn 's|.*refs/tags/v?([^\^]+)(\^\{\})?|\1|p'
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  set -e

  if [[ "$#" -eq 0 ]]
  then
    usage
    exit 2
  fi

  case "$1" in
    help|h|-h|--help)
      usage
      exit 0
      ;;
  esac

  get_latest_release "$1" "$2"
fi

# vim: set ft=sh et ts=2 sw=2 :
