provider "google" {
  credentials = file("~/account.json")
  version     = "~> 2.5"
  project     = var.gcp_project_id
  region      = var.gcp_location
}

