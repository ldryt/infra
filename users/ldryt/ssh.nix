{ ... }:
{
  programs.ssh = {
    hostKeyAlgorithms = [
      "ssh-ed25519"
      "ssh-rsa"
    ];
  };
}
