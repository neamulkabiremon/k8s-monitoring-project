# Required for Terraform to connect to your GKE cluster
data "google_client_config" "default" {}

provider "helm" {
  kubernetes {
    host                   = google_container_cluster.gke.endpoint
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.gke.master_auth[0].cluster_ca_certificate)
  }
}

resource "helm_release" "nginx_ingress" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.publishService.enabled"
    value = "true"
  }
}

