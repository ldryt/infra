set -euo pipefail

fixed=false
while ! nix flake check -L --keep-going; do
  test "$RENOVATE" = true
  determinate-nixd fix hashes --auto-apply
  git diff --quiet && exit 1
  git config user.name 'github-actions[bot]'
  git config user.email '41898282+github-actions[bot]@users.noreply.github.com'
  git commit -am 'fix(nix): update dependency hashes'
  fixed=true
done
if $fixed; then git push origin "HEAD:$GITHUB_HEAD_REF"; fi
