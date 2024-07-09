locals {
  nix_build_result_path = module.nix-build.result["out"]
  zarina_image_matching_set = fileset(local.nix_build_result_path, "nixos-image-*-x86_64-linux.raw.tar.gz")
  zarina_image_filename = tolist(local.zarina_image_matching_set)[0]
  zarina_image_path = join("/", [local.nix_build_result_path, local.zarina_image_filename])
}

module "nix-build" {
  source              = "github.com/nix-community/nixos-anywhere?ref=1.2.0//terraform/nix-build"

  attribute           = "github:ldryt/infra#zarina"
}

resource "google_storage_bucket" "zarina_bucket" {
  provider = google

  name     = "zarina-gce-images-bucket"
  location = "europe-west1"

  force_destroy            = true
  public_access_prevention = "enforced"
}

resource "google_storage_bucket_object" "zarina_image" {
  provider = google

  name   = "zarina-image.tar.gz"
  source = local.zarina_image_path

  bucket = google_storage_bucket.zarina_bucket.name
}

resource "google_compute_image" "zarina_image" {
  provider = google

  name = "zarina"

  raw_disk {
    source = google_storage_bucket_object.zarina_image.media_link
  }
}
