resource "google_compute_instance" "master" {
  name         = "${var.master_node_prefix}-instance-${count.index}"
  machine_type = "n1-standard-2"
  zone         = var.gcp_location

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  tags = ["master", "node"]

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  count = var.master_node_number
}
resource "google_compute_instance" "worker" {
  name         = "${var.worker_node_prefix}-instance-${count.index}"
  machine_type = "n1-standard-1"
  zone         = var.gcp_location

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  tags = ["worker", "node"]

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  count = var.worker_node_number
}
