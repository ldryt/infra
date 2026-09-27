{ ... }:
{
  ldryt-infra.users.colon = {
    enable = true;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDkuAH3XI/M3jqbK+TNrWuG9/9w565xxICD6CJeuOqrK terraform@infra"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHlbB0gz194Jq9LSwI2OvsLcA+LgIQMWS2dNNhapaA8K ldryt@tinkerbell"
    ];
  };

  ldryt-infra.users.ldryt-remote = {
    enable = true;
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICrWMEQNYGGplLSHZrVitRpUHnfH4yThgVNFdIDdMUyG ldryt@tinkerbell"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIICltEAPhmFGXWvRXpN+1PRAwaTj85L4QlLHwvkw//v ldryt@rosetta"
    ];
  };

  users.users.ldryt.extraGroups = [ "syncthing" ];
}
