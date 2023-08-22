# Terraform State Storage
terraform {
  backend "gcs" {
    bucket = "ols-dev-gcloud-storage-tfstate"
    prefix = "helm/ols-dev-helm-external-dns"
  }
}

data "google_project" "current" {}

# create a GKE cluster with 2 node pools
data "terraform_remote_state" "gcloud_dns_ols" {
  backend = "gcs"

  config = {
    bucket = "ols-dev-gcloud-storage-tfstate"
    prefix = "gcloud-dns/ols-dev-gcloud-dns-blast"
  }
}

module "externaldns" {
  source                 = "../../modules/compute/helm"
  region                 = "asia-southeast2"
  unit                   = "ols"
  env                    = "dev"
  code                   = "helm"
  feature                = "external-dns"
  release_name           = "external-dns"
  repository             = "https://charts.bitnami.com/bitnami"
  chart                  = "external-dns"
  create_service_account = true
  project_id             = data.google_project.current.project_id
  service_account_role   = "roles/dns.admin"
  kubernetes_cluster_role_rules = {
    api_groups = [""]
    resources  = ["services", "endpoints", "pods"]
    verbs      = ["get", "list", "watch"]
  }
  create_managed_certificate = false
  values = []
  helm_sets = [
    # Dont create service acocunt
    {
      name = "serviceAccount.create"
      value = false
    },
    # Use existing service account if create_service_account is set to true
    {
      name = "serviceAccount.name"
      value = "ols-dev-helm-external-dns"
    },
    {
      name  = "provider"
      value = "google"
    },
    {
      name  = "google.project"
      value = data.google_project.current.project_id
    },
    {
      name = "policy"
      value = "sync"
    },
    {
      name  = "zoneVisibility"
      value = data.terraform_remote_state.gcloud_dns_ols.outputs.dns_zone_visibility
    }
  ]
  namespace        = "ingress"
  create_namespace = true
}