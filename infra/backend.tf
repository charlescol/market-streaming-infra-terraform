terraform {
  backend "gcs" {
    bucket = "tfstate-${var.project_id}"
    prefix = "gke"
  }
}