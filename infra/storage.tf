resource "google_compute_disk" "gce-pv-disk" {
  name                      = "gce-pv-disk"
  physical_block_size_bytes = 4096
  size                      = 5
  type                      = "pd-ssd"
  zone                      = var.zone
  project                   = var.project_id
}
