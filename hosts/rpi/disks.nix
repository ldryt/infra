{
  fileSystems."/mnt/ssd1" = {
    device = "/dev/disk/by-uuid/26639b4e-93f4-44a4-b2ce-1da3bdb25ba8";
    fsType = "exfat";
    options = [
      "defaults"
      "nofail"
    ];
  };
}
