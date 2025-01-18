{ config, ... }:
{
  networking.networkmanager.unmanaged = [ "interface-name:wlan0" ];

  boot.blacklistedKernelModules = [
    "rtl8xxxu"
    "r8188eu"
  ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ rtl8188eus-aircrack ];

  services.create_ap = {
    enable = true;
    settings = {
      INTERNET_IFACE = "wlp1s0u1u2";
      WIFI_IFACE = "wlan0";
      SSID = "domus";
      PASSPHRASE = "12345678";
    };
  };
}
