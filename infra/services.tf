//  gcloud compute addresses describe grafana-ip --region=asia-northeast1 --project=market-streaming-prod --format="get(address)" 
resource "google_compute_address" "grafana_ip" {
  name         = "grafana-ip"
  project      = var.project_id
  region       = var.region
  address_type = "EXTERNAL"
}

output "grafana_ip" {
  value = google_compute_address.grafana_ip.address
}
