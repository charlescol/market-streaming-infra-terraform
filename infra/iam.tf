

data "google_service_account" "terraform" {
  account_id = "terraform"
  project    = var.project_id
}
