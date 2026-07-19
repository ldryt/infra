resource "scaleway_iam_ssh_key" "vidia_install" {
  count      = var.vidia ? 1 : 0
  name       = "vidia_install"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDPtZ3xwPiGmFigIOz5ISVuD/o5YwQcOrxBlviKSHkyx nixos-anywhere-install@ovh-vidia"
}

resource "scaleway_instance_ip" "vidia" {
  count = var.vidia ? 1 : 0
  zone  = "fr-par-2"
  type  = "routed_ipv4"
}

resource "scaleway_instance_server" "vidia" {
  count  = var.vidia ? 1 : 0
  name   = "vidia"
  zone   = "fr-par-2"
  type   = "L4-1-24G"
  image  = "66cf8f1a-b0dd-49ce-9b22-d8949f34648f"
  ip_ids = [scaleway_instance_ip.vidia[0].id]
  root_volume {
    size_in_gb  = 300
    volume_type = "sbs_volume"
  }
  lifecycle {
    ignore_changes = [image]
  }
  depends_on = [scaleway_iam_ssh_key.vidia_install]
}
