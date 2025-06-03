resource "google_service_account" "terraform" {
  account_id   = "terraform"
  display_name = "Terraform Bootstrap / IaC"
  description  = "Service account for Terraform IaC"
}

resource "google_service_account_key" "tf_key" {
  service_account_id = google_service_account.terraform.name
  keepers = {
    generation = 1
  }
}

resource "google_service_account" "artifact_deployer" {
  account_id   = "artifact-deployer"
  display_name = "Artifact Registry Deployer"
  description  = "Service account for deploying artifacts to Artifact Registry"
}
