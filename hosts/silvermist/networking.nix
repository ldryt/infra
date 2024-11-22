{
  networking = {
    hostName = "silvermist";
    useDHCP = false;
    interfaces."eth0".useDHCP = true;
  };
}
