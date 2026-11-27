{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.secrets."pi/mail/clearPassword" = { };

  programs.msmtp = {
    enable = true;
    configContent = ''
      account pi
      host mx.ldryt.dev
      port 465
      tls on
      tls_starttls off
      auth on
      user pi@ldryt.dev
      from pi@ldryt.dev
      set_to_header on
      passwordeval ${pkgs.coreutils}/bin/cat ${
        lib.escapeShellArg config.sops.secrets."pi/mail/clearPassword".path
      }
    '';
  };

  home.packages = [
    (pkgs.writeShellScriptBin "notify" ''
      set -eo pipefail
      subject="''${1:?Usage: notify SUBJECT < body.txt}"
      subject="''${subject//[$'\r\n']/ }"
      origin="$(${pkgs.coreutils}/bin/id -un)@$HOSTNAME"
      origin="''${origin//[^a-zA-Z0-9@._-]/_}"

      {
        printf 'From: "%s" <"pi+%s"@ldryt.dev>\nSubject: %s\n\n' "$origin" "$origin" "$subject"
        ${pkgs.coreutils}/bin/cat
      } | ${pkgs.msmtp}/bin/msmtp --account=pi -- ldryt@ldryt.dev
    '')
  ];

  home.file.".pi/agent/skills/email/SKILL.md".text = ''
    ---
    name: email
    description: Send an email notification.
    ---

    Sends a notification to the user.
    Usage: `printf '%s\n' 'Message body' | notify 'Subject'`.
  '';
}
