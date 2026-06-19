{ config, ... }:
{
  ldryt-infra.persist.directories = [ config.services.cachefilesd.cacheDir ];
  services.cachefilesd = {
    enable = true;
    extraConfig = ''
      brun 20%
      bcull 15%
      bstop 10%
    '';
  };
}
