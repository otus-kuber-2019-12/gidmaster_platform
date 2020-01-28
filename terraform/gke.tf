resource "google_container_cluster" "cluster" {
  location = var.gcp_location

  name = var.gcp_cluster_name

  min_master_version = "latest"

  maintenance_policy {
    daily_maintenance_window {
      start_time = var.daily_maintenance_window_start_time
    }
  }

  network_policy {
    enabled  = true
    provider = "CALICO"
  }

  addons_config {

    network_policy_config {
      disabled = false
    }
  }
  remove_default_node_pool = true
  initial_node_count       = 1

  timeouts {
    update = "20m"
  }
}

resource google_container_node_pool "node_pool" {
  name               = var.gcp_pool_name
  location           = google_container_cluster.cluster.location
  cluster            = google_container_cluster.cluster.name
  initial_node_count = 1
  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  node_config {
    machine_type = var.worker_machine_type
    disk_size_gb = var.worker_disk_size

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  timeouts {
    create = "60m"
    update = "60m"
    delete = "60m"
  }
}
