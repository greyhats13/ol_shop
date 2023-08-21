# Terraform State Storage
terraform {
  backend "gcs" {
    bucket = "ols-dev-gcloud-storage-tfstate"
    prefix = "gcloud-kms/ols-dev-gcloud-kms-ols"
  }
}

# create cloud dns module

module "gcloud_kms" {
  source           = "../../modules/security/gcloud-kms"
  region           = "asia-southeast2"
  unit             = "ols"
  env              = "dev"
  code             = "gcloud-dns"
  feature          = "blast"
  zone_name        = "ols-blast"
  dns_name         = "ols.blast.co.id."
  zone_description = "Gcloud DNS for for ols.blast.co.id"
  force_destroy    = true
  visibility       = "public"
}
