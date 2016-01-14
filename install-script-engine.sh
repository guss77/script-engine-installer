#!/bin/bash

###
# A minimal shell script to install scripting engines locally according to a simple spec file
# 
# (c) Oded Arbel 2015; Licensed under MIT license
# 
# Uses a .versions.conf file (as is common practice for RMV) and installs the specified scripting
# engines and their management tools, as required.
#
# Currently supported tools:
# - Ruby (using RVM)
# - Node.js (using NVM)
#
# Currently supported operating systems:
# - Ubuntu 14.04
##

GPG="$(which gpg)"
CURL="$(which curl)"
AWK="$(which awk)"

function die() {
  echo "$@" >&2
  exit 1
}

function get_rvm_installer() {
  local rvm_source_url=(
    $RVM_URL
    https://get.rvm.io
    https://raw.githubusercontent.com/wayneeseguin/rvm/master/binscripts/rvm-installer
    )
  for url in "${rvm_source_url[@]}"; do
    curl -sSL "$url" && return
  done
}

function rvm_base_dir() {
  if [ -n "$INSTALL_CWD" ]; then
    echo "$(pwd)/.rvm"
  elif [ "$(id -u)" == "0" ]; then
    echo "/usr/local/rvm"
  else
    echo "$HOME/.rvm"
  fi
}

function un_ansi() {
  sed -e 's/\o33\[[0-9]\+m//g'
}

function all_ok() { 
  for v in "$@"; do 
    [ "$v" == 0 ] || return 1
  done
}

function bin_dir() {
  if [ "$(id -u)" != "0" ]; then
    for path in $(echo $PATH | tr ':' ' '); do
      egrep -q "^$HOME" <<<$path || continue
      echo $path
      return 0
    done
  fi
  echo "/usr/local/bin"
}

function add_to_path() {
  lbin_dir="$(bin_dir)/"
  while [ -n "$1" ]; do
    ln -sf "$1" "$lbin_dir"
    shift
  done
}

function install_ruby() {
  local version="$1"
  [ -x "$GPG" ] || die "Missing gpg"
  [ -x "$CURL" ] || die "Missing curl"
  if ! ($GPG --list-keys | grep -q D39DC0E3); then
    (for i in {1..3}; do
      $GPG --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3 && exit 0
    done
    # fallback to loading the key directly from rvm.io
    curl -L https://rvm.io/mpapis.asc | $GPG --import -
    ) || die "Failed to get RVM key"
  fi
  if [ -d "$(rvm_base_dir)" ]; then
    $(rvm_base_dir)/bin/rvm-shell -c 'rvm get stable'
  else
    get_rvm_installer | bash -s -- --path "$(rvm_base_dir)" stable
    all_ok "${PIPESTATUS[@]}" || die "Failed to install RVM"
  fi | un_ansi
  if [ -n "$INSTALL_CWD" ]; then
    source .rvm/scripts/rvm
  else
    source /etc/profile.d/rvm.sh
  fi
  rvm list strings | egrep -q "ruby-$version" && return 0
  rvm install "$1" > >(un_ansi) 2>*1 || die "Failed to install Ruby '$version'"
  rvm use "$1" default || die "Failed to set Ruby '$version' to default"
  add_to_path $(rvm_base_dir)/wrappers/default/*
}

function install_node() {
  [ -x "$CURL" ] || die "Missing curl"
  [ -n "$INSTALL_CWD" ] && export NVM_DIR="$(pwd)/.nvm"
  (
    curl -sL https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash || die "Failed to install NVM"
    source $HOME/.nvm/nvm.sh || die "Failed to load NVM"
    nvm install "$1" || die "Failed to install Node.js '$1'"
    nvm alias default "$1" || die "Failed to set Node.js '$1' as default version"
    add_to_path $(dirname $(nvm which default))/*
  ) | un_ansi
}

function install_debian() {
  for engine in "${INSTALL_SCRIPT_ENGINES[@]}"; do
    IFS=- read name version <<<"$engine"
    install_$name "$version" || die "Failed to install ruby"
  done
  true
}

source /etc/lsb-release

SUPPORTED_SCRIPT_ENGINES=( ruby node )
INSTALL_SCRIPT_ENGINES=()

[ -f .versions.conf ] || die "Please provide a valid .versions.conf"
[ -x "$AWK" ] || die "Missing awk"

while [ -n "$1" ]; do
    while getopts l opt; do
      case "$opt" in
      l) INSTALL_CWD=1;;
      esac
    done
    shift $((OPTIND-1))
done

for engine in "${SUPPORTED_SCRIPT_ENGINES[@]}"; do
  version="$($AWK -F= '$1=="'"$engine"'"{print$2}' < .versions.conf)"
  [ -z "$version" ] && continue
  INSTALL_SCRIPT_ENGINES+=( "${engine}-${version}" )
done

case $DISTRIB_ID in
(Ubuntu) install_debian;;
(*) echo "Unrecognized operating system: '$DISTRIB_ID'!" >&2
esac
