#!/usr/bin/env bash

# noisepage related
function noisepage::init() {
  common::say "Installing dependencies for [noisepage]"
  __noisepage::install
}

function noisepage::serve() {
  common::say "Serve workspace for [noisepage]"
  common::serve
}

# ydb related
function ydb::init() {
  common::say "Installing dependencies for [ydb]"
  wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
  wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc | sudo apt-key add -
  echo 'deb http://apt.kitware.com/ubuntu/ focal main' | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null
  echo 'deb http://apt.llvm.org/focal/ llvm-toolchain-focal main' | sudo tee /etc/apt/sources.list.d/llvm.list >/dev/null
  sudo apt-get update
  sudo apt-get -y install git cmake python python3-pip ninja-build antlr3 m4 clang-12 lld-12 libidn11-dev libaio1 libaio-dev
  sudo pip3 install conan
}

function ydb::serve() {
  common::say "Serve workspace for [ydb]"
  common::serve
}

function __noisepage::install() {
  sudo apt-get update -y
  sudo apt-get -y install \
    build-essential \
    clang-6.0 \
    clang-format-6.0 \
    clang-tidy-6.0 \
    cmake \
    doxygen \
    git \
    g++-7 \
    libboost-filesystem-dev \
    libjemalloc-dev \
    libjsoncpp-dev \
    libtbb-dev \
    libz-dev \
    llvm-6.0
  # Packages to be installed through pip3.
  PYTHON_PACKAGES=("distro")
  common::say "Installing Python packages"
  for pkg in "${PYTHON_PACKAGES[@]}"; do
    python3 -m pip show "$pkg" || python3 -m pip install "$pkg"
  done
}

# Install default toolchain for CPP, including clang-8, build-essentials, cmake, ninja
function cpp::init() {
  common::say "Installing default CPP toolchain"
  sudo apt-get update -y
  local packages=(
    "build-essential"
    "clang-8"
    "clang-format-8"
    "clang-tidy-8"
    "cmake"
    "llvm-8"
    "pkg-config"
    "ninja-build"
    "wget"
    "ccache"
    "lcov"
    "lsof"
  )
  sudo apt-get -y --no-install-recommends install $(
    IFS=$' '
    echo "${packages[*]}"
  )
}

function cpp::serve() {
  common::say "Serve workspace for CPP development"
  common::serve
}

function python::init() {
  common::say "Installing default Python toolchain"
  sudo apt-get update -y
  local linux_packages=(
    "python3-pip"
  )
  sudo apt-get -y --no-install-recommends install $(
    IFS=$' '
    echo "${linux_packages[*]}"
  )
  local python_modules=(
    "coverage"
  )
  for pkg in "${python_modules[@]}"; do
    python3 -m pip show "$pkg" || python3 -m pip install "$pkg"
  done
}

function python::serve() {
  common::say "Serve workspace for Python development"
  common::serve
}

function base::serve() {
  common::serve_ssh
  tail -f /dev/null
}

function common::serve() {
  common::serve_ssh
  tail -f /dev/null
}

function common::serve_ssh() {
  common::say "Starting the SSH server."
  service ssh start
  service ssh status
}

function common::say() {
  printf '\n\033[0;44m---> %s \033[0m\n' "$1"
}

function common::ensure() {
  if ! "$@"; then common::err "command failed: $*"; fi
}

function common::err() {
  common::say "$1" >&2
  exit 1
}

function common::usage() {
  cat <<EOF
USAGE:
    entrypoint.sh [PROJECTS] [COMMAND]
PROJECTS:
    noisepage           Start workspace for noisepage project
    cpp                 Start general CPP workspace
    python              Start general Python workspace
    ydb			Start workspace for ydb project
    base
COMMAND:
    init                Initiate a development workspace for the project
    serve               Run the workspace for the project
EOF
}

function main() {
  local project=""
  local command=""
  if [[ $# -eq 0 ]]; then
    common::usage
    exit 1
  fi
  while [[ $# -gt 0 ]]; do
    key="$1"
    case "$key" in
    base | ydb | noisepage | cpp | python)
      project="$1"
      command="$2"
      break
      ;;
    *)
      common::usage
      exit 0
      ;;
    esac
  done
  func="${project}::${command}"
  eval "$func"
}

main "$@" || exit 1
