resource "google_artifact_registry_repository" "repos" {
  for_each      = toset(var.services)
  provider      = google-beta
  repository_id = each.value
  location      = var.region
  description   = "Docker registry for ${each.value}"
  format        = "DOCKER"

  cleanup_policies {
    id     = "delete-untagged"
    action = "DELETE"
    condition {
      tag_state  = "UNTAGGED"
      older_than = "1d"
    }
  }

  cleanup_policies {
    id     = "keep-minimum-versions"
    action = "KEEP"
    most_recent_versions {
      package_name_prefixes = [""]
      keep_count            = 3
    }
  }
}
