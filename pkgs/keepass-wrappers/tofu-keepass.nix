{ pkgs }:
let
  keepass_cmd = "keepassxc-cli show -q -a";

  DB_PATH = "$HOME/Sync/Vault/keyring.kdbx";

  TF_VAR_ENTRIES = [
    "state_passphrase"
    "desec_token"
    "hcloud_token"
  ];
  TF_VAR_ATTR = "notes";

  SOPS_KEY_ENTRY = "ldryt - sops";
  SOPS_KEY_ATTR = "notes";

  genTfVarExports =
    entries:
    builtins.concatStringsSep "\n" (
      map (entry: ''
        TF_VAR_${entry}="$(
          echo "$KEEPASS_PASSWORD" | ${keepass_cmd} "${TF_VAR_ATTR}" "${DB_PATH}" "${entry}"
        )"
        export TF_VAR_${entry}
      '') entries
    );
in
pkgs.writeShellApplication {
  name = "tofu-keepass";

  runtimeInputs = with pkgs; [
    opentofu
    keepassxc
    jq
  ];

  text = ''
    set -euo pipefail

    read -rsp "Enter password to unlock ${DB_PATH}: " KEEPASS_PASSWORD
    echo

    SOPS_AGE_KEY_FILE="$(umask 077; mktemp)"
    trap 'rm -f "$SOPS_AGE_KEY_FILE"' EXIT

    echo "$KEEPASS_PASSWORD" | ${keepass_cmd} "${SOPS_KEY_ATTR}" "${DB_PATH}" "${SOPS_KEY_ENTRY}" > "$SOPS_AGE_KEY_FILE"

    ${genTfVarExports TF_VAR_ENTRIES}

    unset KEEPASS_PASSWORD

    export SOPS_AGE_KEY_FILE
    tofu "$@"
  '';
}
