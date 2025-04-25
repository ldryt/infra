#!/usr/bin/env bash

set -xeu

mkdir -p ./nix

cp "$HOME/.keyring/sops_age_$SERVER_NAME.key" ./nix/
