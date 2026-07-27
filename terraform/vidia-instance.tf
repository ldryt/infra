resource "openstack_compute_keypair_v2" "vidia_install" {
  count      = var.vidia ? 1 : 0
  name       = "lucas-ladreyt-vidia-install"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDPtZ3xwPiGmFigIOz5ISVuD/o5YwQcOrxBlviKSHkyx nixos-anywhere-install@ovh-vidia"
}

resource "openstack_compute_instance_v2" "vidia" {
  count       = var.vidia ? 1 : 0
  name        = "lucas-ladreyt-vidia"
  flavor_name = "h100-380"
  image_name  = "Debian 12"
  key_pair    = openstack_compute_keypair_v2.vidia_install[0].name

  network {
    name = "Ext-Net"
  }

  lifecycle {
    ignore_changes = [key_pair]
  }
}
