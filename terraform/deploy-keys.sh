#!/usr/bin/env bash
set -xeu

mkdir -p ./nix/persist

umask 077
echo "$SERVER_SOPS_KEY" > "./nix/persist/sops_age_$SERVER_NAME.key"

if [ -n "${SECUREBOOT_BUNDLE:-}" ]; then
  dest="./nix/persist/etc/secureboot"
  mkdir -p "$dest"

  printf '%s' "$SECUREBOOT_BUNDLE" | base64 -d | tar -xz -C "$dest"
  chmod -R go-rwx "$dest/keys"

  mkdir -p ./etc
  cp -a "$dest" ./etc/secureboot
fi
