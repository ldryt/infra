#!/usr/bin/env bash
set -xeu

mkdir -p ./nix/persist

umask 077
echo "$SERVER_SOPS_KEY" > "./nix/persist/sops_age_$SERVER_NAME.key"
