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

function rvm_base_dir() {
  if [ "$(id -u)" == "0" ]; then
    echo "/usr/local/rvm"
  else
    echo "$HOME/.rvm"
  fi
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
  [ -x "$GPG" ] || die "Missing gpg"
  [ -x "$CURL" ] || die "Missing curl"
  if ! ($GPG --list-keys | grep -q D39DC0E3); then
    $GPG --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3 || die "Failed to get RVM key"
  fi
  if [ -d "$(rvm_base_dir)" ]; then
    $(rvm_base_dir)/bin/rvm-shell -c 'rvm get stable'
  else
    $CURL -sL https://get.rvm.io | bash -s stable || die "Failed to install RVM"
  fi
  source /etc/profile.d/rvm.sh
  rvm install "$1" || die "Failed to install Ruby '$1'"
  rvm use "$1" default || die "Failed to set Ruby '$1' to default"
  add_to_path $(rvm_base_dir)/wrappers/default/*
}

function install_node() {
  [ -x "$CURL" ] || die "Missing curl"
  curl -sL https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash || die "Failed to install NVM"
  source $HOME/.nvm/nvm.sh || die "Failed to load NVM"
  nvm install "$1" || die "Failed to install Node.js '$1'"
  nvm alias default "$1" || die "Failed to set Node.js '$1' as default version"
  add_to_path $(nvm which default)
}

function install_debian() {
  [ -n "$ruby" ] && { install_ruby "$ruby" || die "Failed to install ruby"; }
  [ -n "$node" ] && { install_node "$node" || die "Failed to install node.js"; }
}

source /etc/lsb-release

[ -x "$AWK" ] || die "Missing awk"

ruby="$($AWK -F= '$1=="ruby"{print$2}' < .versions.conf)"
node="$($AWK -F= '$1=="node"{print$2}' < .versions.conf)"

case $DISTRIB_ID in
(Ubuntu) install_debian;;
(*) echo "Unrecognized operating system: '$DISTRIB_ID'!" >&2
esac
