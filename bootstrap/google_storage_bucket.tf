resource "google_storage_bucket" "tfstate" {
  name                        = "tfstate-${var.project_id}"
  location                    = var.region
  uniform_bucket_level_access = true

  versioning { enabled = true }

  lifecycle_rule {
    condition { age = 30 }
    action    { type = "Delete" }
    # action    { type = "SetStorageClass", storage_class = "COLDLINE" }
  }
}

output "bucket_name" {
  value = google_storage_bucket.tfstate.name
}