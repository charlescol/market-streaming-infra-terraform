

data "google_service_account" "terraform" {
  account_id = "terraform"
  project    = var.project_id
}

data "google_service_account" "terraform" {
  account_id = "gke-node-sa"
  project    = var.project_id
}
