#!/usr/bin/env bash
set -x

function common::say() {
  printf '\n---> %s \n' "$1"
}

function common::ensure() {
  if ! "$@"; then common::err "command failed: $*"; fi
}

function common::err() {
  common::say "$1" >&2
  exit 1
}



function setup() {
  local force_build="$1"
  local compose_opts="--detach"
  common::say "Setup dev containers"
  if [ "$force_build" == "true" ]; then
    compose_opts="$compose_opts --build"
  fi
  docker-compose --file="$2" up $compose_opts
  docker-compose --file="$2" logs -f
  common::say "Setup SSH client"
  sshpass -p "passward" ssh-copy-id -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null -p 2222 master@localhost
}

function stop() {
  common::say "Stop dev containers"
  docker-compose -f "$1" stop
}

function start() {
  common::say "Start dev containers"
  docker-compose -f "$1" start
}

function status() {
    docker-compose -f "$1" ps
}

function teardown() {
  common::say "Shutdown dev containers"
  docker-compose -f "$1" down
}

function usage() {
  cat <<EOF
USAGE:
    setup.sh [options] [command] [compose file]
OPTIONS:
    -b, --build   Force rebuild of the docker image
COMMANDS:
    up            Setup development workspace
    start         Resume a suspended workspace
    stop          Suspend a workspace
    down          Teardown everything
EOF
}

function main() {
  local force_build=false
  if [[ $# -eq 0 ]]; then
    usage
    exit 1
  fi
  while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
    -h | --help)
      usage
      exit 0
      ;;
    -b | --build)
      force_build=true
      shift
      ;;
    up)
      setup "$force_build" "$2"
      exit 0
      ;;
    start)
      start "$2"
      exit 0
      ;;
    status)
      status "$2"
      exit 0
      ;;
    stop)
      stop "$2"
      exit 0
      ;;
    down)
      teardown "$2"
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
    esac
  done
}

main "$@"
