resource "google_secret_manager_secret" "gke_sa_key" {
  secret_id = "gke-sa-key"

  replication {
    auto {}
  }
}
