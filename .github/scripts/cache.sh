set -euo pipefail

mkdir -p ~/.ssh
printf '%s\n' "$SSH_KNOWN_HOSTS" >> ~/.ssh/known_hosts
eval "$(ssh-agent -s)"
printf '%s\n' "$NIX_CACHE_SSH_PRIVKEY" | ssh-add -
nix eval --json ".#checks.$(nix config show system)" | jq -r '.[]' | nix copy --stdin --to ssh://nix-ssh@nix-cache.ldryt.dev
