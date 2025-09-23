resource "google_container_cluster" "gke_cluster" {
  name     = var.cluster_name
  location = var.zone
  project  = var.project_id

  deletion_protection      = false
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = "default"
  subnetwork = "default"

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.20.0.0/16"
    services_ipv4_cidr_block = "10.30.0.0/20"
  }

  logging_service    = "none"
  monitoring_service = "none"

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  cluster    = google_container_cluster.gke_cluster.name
  location   = var.zone
  project    = var.project_id
  node_count = 2

  node_config {
    machine_type = "e2-custom-24-32768" # Check availability: gcloud compute machine-types describe {machine_type} --zone={zone}

    confidential_nodes {
      enabled = false
    }
    disk_size_gb                = 30
    disk_type                   = "pd-ssd"
    enable_confidential_storage = false
    # local_ssd_count             = 1


    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    service_account = data.google_service_account.gke_nodes.email
    metadata = {
      disable-legacy-endpoints = "true"
    }
    tags = ["gke-node"]
  }

  autoscaling {
    min_node_count = 2
    max_node_count = 2
  }

  management {
    auto_upgrade = true
    auto_repair  = true
  }
}
