variable "create_zarina_instance" {
  type = bool
}

locals {
  keynames = [
    "ssh_host_rsa_key",
    "ssh_host_rsa_key.pub",
    "ssh_host_ed25519_key",
    "ssh_host_ed25519_key.pub"
  ]
}

resource "google_compute_network" "zarina_network" {
  provider = google

  name = "zarina"
}

resource "google_compute_firewall" "zarina_firewall" {
  provider = google

  name    = "zarina"
  network = google_compute_network.zarina_network.self_link

  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "25565"]
  }
}

resource "google_compute_instance" "zarina_instance" {
  count    = var.create_zarina_instance ? 1 : 0
  provider = google-beta

  name         = "zarina"
  machine_type = "c2d-standard-2"
  zone         = "europe-west1-d"

  boot_disk {
    initialize_params {
      size  = "30"
      type  = "pd-ssd"
      image = google_compute_image.zarina_image.self_link
    }
  }

  network_interface {
    network = google_compute_network.zarina_network.self_link
    access_config {}
  }

  scheduling {
    instance_termination_action = "DELETE"
    max_run_duration {
      seconds = 60 * 60 * 12 // 12 hours
    }
  }

  metadata_startup_script = <<-EOT
    if [ ! -f /var/startup_script_success ]; then
      touch /var/startup_script_success

      ${join("\n", [for _, keyname in local.keynames : <<-SCRIPT
        if [[ ${keyname} == *.pub ]]; then
          umask 0133
        else
          umask 0177
        fi
        echo "${base64encode(data.sops_file.zarina_secrets.data["system.ssh.${keyname}"])}" \
          | base64 --decode > /etc/ssh/${keyname}
      SCRIPT
])}

      reboot
    fi
  EOT
}
