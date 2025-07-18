{ pkgs }:
let
  keepass_cmd = "${pkgs.keepassxc}/bin/keepassxc-cli show -q -a";

  DB_PATH = "$HOME/Sync/Vault/keyring.kdbx";
  ENTRY = "ldryt - sops";
  ATTR = "notes";
in
pkgs.writeShellScriptBin "sops-keepass" ''
  set -euo pipefail

  read -rsp "Enter password to unlock ${DB_PATH}: " KEEPASS_PASSWORD
  echo

  export SOPS_AGE_KEY_FILE="$(umask 077; mktemp)"
  trap 'rm -f "$SOPS_AGE_KEY_FILE"' EXIT

  echo "$KEEPASS_PASSWORD" | ${keepass_cmd} "${ATTR}" "${DB_PATH}" "${ENTRY}" > $SOPS_AGE_KEY_FILE

  unset KEEPASS_PASSWORD

  "${pkgs.sops}/bin/sops" "$@"
''
