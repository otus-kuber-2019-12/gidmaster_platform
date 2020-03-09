variable "gcp_project_id" {
  description = "project ID"
}

variable "gcp_location" {
  description = "region name"
  default     = "europe-west1-a"
}

variable "gcp_cluster_name" {
  description = "k8s Cluster name"
}

variable "daily_maintenance_window_start_time" {
  description = ""
  default     = "04:00"
}

variable "gcp_pool_name_infra" {
  description = "name of kubernetes Infra node pool"
}

variable "worker_disk_size" {
  description = ""
}

variable "worker_machine_type" {
  description = ""
}

variable "address_name" {
  description = "name of address pool"
}
