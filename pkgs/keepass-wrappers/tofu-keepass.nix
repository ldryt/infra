{ pkgs }:
pkgs.writeShellApplication {
  name = "tofu-keepass";

  runtimeInputs = with pkgs; [
    opentofu
    keepassxc
    jq
  ];

  text = ''
    db_path="$HOME/Sync/Vault/keyring.kdbx"
    read -rsp "Enter password to unlock $db_path: " keepass_password
    printf '\n'

    keepass_notes() {
      printf '%s\n' "$keepass_password" | keepassxc-cli show -q -a notes "$db_path" "$1"
    }

    SOPS_AGE_KEY_FILE="$(umask 077; mktemp)"
    trap 'rm -f "$SOPS_AGE_KEY_FILE"' EXIT

    keepass_notes "ldryt - sops" > "$SOPS_AGE_KEY_FILE"
    TF_VAR_state_passphrase="$(keepass_notes state_passphrase)"
    TF_VAR_desec_token="$(keepass_notes desec_token)"
    unset keepass_password

    export SOPS_AGE_KEY_FILE TF_VAR_state_passphrase TF_VAR_desec_token
    tofu "$@"
  '';
}
