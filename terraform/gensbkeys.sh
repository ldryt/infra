#! /usr/bin/env nix-shell
#! nix-shell -i bash -p sbctl
set -euo pipefail

out="$PWD/secureboot"
mkdir -p "$out"

cat > "$out/sbctl.conf" <<EOF
keydir: $out/keys
guid: $out/GUID
files_db: $out/files.json
landlock: false
EOF

sbctl --config "$out/sbctl.conf" create-keys
rm -f "$out/sbctl.conf" "$out/files.json"

find "$out"

tar -cz -C secureboot . | base64 -w0 > "$out/all.b64"
