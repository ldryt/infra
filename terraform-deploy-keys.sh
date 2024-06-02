#!/usr/bin/env bash

mkdir -p ./etc/ssh ./var/lib/sops

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SECRETS_FILE="$SCRIPT_DIR/hosts/$SERVER_NAME/secrets.yaml"

umask 0177
cp "$KEYRING_PATH/sops_age_$SERVER_NAME.key" ./var/lib/sops
umask 0022

for keyname in ssh_host_rsa_key ssh_host_rsa_key.pub ssh_host_ed25519_key ssh_host_ed25519_key.pub; do
  if [[ $keyname == *.pub ]]; then
    umask 0133
  else
    umask 0177
  fi
  sops --extract '["system"]["ssh"]["'$keyname'"]' -d "$SECRETS_FILE" >"./etc/ssh/$keyname"
done
