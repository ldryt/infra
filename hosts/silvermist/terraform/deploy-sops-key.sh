#!/usr/bin/env bash

set -xeu

mkdir -p ./nix

keepassxc-cli show -a notes "$KEEPASS_DB" "$SERVER_NAME - sops" > "./nix/sops_age_$SERVER_NAME.key"
