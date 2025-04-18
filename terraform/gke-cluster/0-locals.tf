locals {
  project_id = "serious-physics-452107-d1"
  region     = "us-central1"
  apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "logging.googleapis.com",
    "secretmanager.googleapis.com"
  ]
}