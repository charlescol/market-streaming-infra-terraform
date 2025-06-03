resource "google_service_account" "terraform" {
  account_id   = "terraform"
  display_name = "Terraform Bootstrap / IaC"
}

# Necessary roles for Terraform to operate
resource "google_project_iam_member" "terraform_roles" {
  for_each = toset([
    "roles/container.admin",
    "roles/iam.serviceAccountUser",
    "roles/artifactregistry.admin",
    "roles/storage.admin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/servicemanagement.admin",
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

resource "google_service_account" "artifact_deployer" {
  account_id   = "artifact-deployer"
  display_name = "Artifact Registry Deployer"
}

resource "google_project_iam_member" "artifact_registry_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.artifact_deployer.email}"
}


resource "google_service_account_key" "tf_key" {
  service_account_id = google_service_account.terraform.name
  keepers = {
    generation = 1
  }
}
