{ pkgs }:
let
  keepass_cmd = "keepassxc-cli show -q -a";

  DB_PATH = "$HOME/Sync/Vault/keyring.kdbx";

  SOPS_KEY_ENTRY = "ldryt - sops";
  SOPS_KEY_ATTR = "notes";
  SSH_KEY_ENTRY = "clank - ssh";
in
pkgs.writeShellApplication {
  name = "ansible-keepass";

  runtimeInputs = with pkgs; [
    ansible
    keepassxc
    sops
    openssh
  ];

  text = ''
    set -euo pipefail

    read -rsp "Enter password to unlock ${DB_PATH}: " KEEPASS_PASSWORD
    echo

    SOPS_AGE_KEY_FILE="$(umask 077; mktemp)"
    trap 'rm -f "$SOPS_AGE_KEY_FILE"' EXIT

    echo "$KEEPASS_PASSWORD" | ${keepass_cmd} "${SOPS_KEY_ATTR}" "${DB_PATH}" "${SOPS_KEY_ENTRY}" > "$SOPS_AGE_KEY_FILE"

    ANSIBLE_PRIVATE_KEY="$(
      echo "$KEEPASS_PASSWORD" | ${keepass_cmd} notes "${DB_PATH}" "${SSH_KEY_ENTRY}"
    )"

    unset KEEPASS_PASSWORD

    export SOPS_AGE_KEY_FILE ANSIBLE_PRIVATE_KEY
    export ANSIBLE_SSH_AGENT=auto
    ansible-playbook "$@"
  '';
}
