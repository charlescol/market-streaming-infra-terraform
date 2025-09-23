resource "google_storage_bucket" "druid_storage" {
  name                        = "druid-storage-${var.project_id}"
  location                    = var.region
  uniform_bucket_level_access = true

  force_destroy = true
  versioning { enabled = true }
}
