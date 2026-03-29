#!/usr/bin/env bash
set -euo pipefail

readonly APP_NAME="coteditor"
COUNT=3

log_info() {
  local message="$1"
  echo "[$APP_NAME] $message"
}

build_path() {
  local base="${1:-/tmp}"
  echo "${base}/build-${COUNT}"
}

main() {
  local path
  path="$(build_path "/var/tmp")"

  if [[ -d "$path" ]]; then
    log_info "already exists: $path"
  else
    mkdir -p "$path"
    log_info "created: $path"
  fi

  for i in 1 2 3; do
    echo "step $i"
  done

  case "$COUNT" in
    0) echo "empty" ;;
    1|2) echo "small" ;;
    *) echo "many" ;;
  esac
}

main "$@"
