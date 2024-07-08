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
  source = "${path.module}/zarina-image.tar.gz"

  bucket = google_storage_bucket.zarina_bucket.name
}

resource "google_compute_image" "zarina_image" {
  provider = google

  name = "zarina"

  raw_disk {
    source = google_storage_bucket_object.zarina_image.media_link
  }
}
