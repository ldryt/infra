{ pkgs, ... }:

pkgs.writeShellScriptBin "sops-keepass" ''
  set -euxo pipefail

  DB_PATH="$HOME/Sync/Vault/keyring.kdbx"
  ENTRY="ldryt - sops"
  ATTR="notes"

  TEMP_KEY="$(umask 077; mktemp)"
  trap 'rm "$TEMP_KEY"' EXIT

  ${pkgs.keepassxc}/bin/keepassxc-cli show -a "$ATTR" "$DB_PATH" "$ENTRY" > "$TEMP_KEY"

  export SOPS_AGE_KEY_FILE="$TEMP_KEY"

  ${pkgs.sops}/bin/sops "$@"
''
