
resource "google_artifact_registry_repository" "docker_repo" {
  provider      = google-beta
  repository_id = var.artifact_repo_name
  location      = var.region
  description   = "Docker registry for application containers"
  format        = "DOCKER"
}
