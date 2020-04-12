variable "gcp_project_id" {
  description = "project ID"
}

variable "gcp_location" {
  description = "region name"
  default     = "us-central1-a"
}

variable "master_node_prefix" {
  description = "prefix for master nodes"
}

variable "worker_node_prefix" {
  description = "prefix for master nodes"
}

variable "master_node_number" {
  description = "number for master nodes"
  default = 1
}

variable "worker_node_number" {
  description = "number for worker nodes"
  default = 3
}

variable "master_node_machine_type" {
  default = "n1-standard-1"
  description = "machine_type parameter for GCP instance"
}

variable "worker_node_machine_type" {
  default = "n1-standard-1"
  description = "machine_type parameter for GCP instance"
}
