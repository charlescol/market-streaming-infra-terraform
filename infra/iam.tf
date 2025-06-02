resource "google_service_account" "terraform" {
  account_id   = "terraform"
  display_name = "Terraform Service Account"
}

resource "google_project_iam_member" "terraform_roles" {
  for_each = toset([
    "roles/container.admin",
    "roles/iam.serviceAccountUser",
    "roles/artifactregistry.admin",
    "roles/storage.admin"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.terraform.email}"
}

resource "google_service_account_key" "tf_key" {
  service_account_id = google_service_account.terraform.name
}