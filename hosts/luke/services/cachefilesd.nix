{ config, ... }:
{
  ldryt-infra.persist.directories = [ config.services.cachefilesd.cacheDir ];
  services.cachefilesd = {
    enable = true;
    extraConfig = ''
      brun 40%
      bcull 35%
      bstop 30%
    '';
  };
}
