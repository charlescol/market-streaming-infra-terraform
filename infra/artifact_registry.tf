resource "google_artifact_registry_repository" "repos" {
  for_each      = toset(var.services)
  provider      = google-beta
  repository_id = each.value
  location      = var.region
  description   = "Docker registry for ${each.value}"
  format        = "DOCKER"
}
