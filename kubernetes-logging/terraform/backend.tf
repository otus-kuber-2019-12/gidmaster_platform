terraform {
  backend "gcs" {
    bucket      = "tf-state-k8s-platform"
    prefix      = "terraform/state"
    credentials = "~/account.json"
  }
}
