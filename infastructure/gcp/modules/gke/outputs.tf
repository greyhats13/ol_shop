output "kubeconfig" {
  value = google_container_cluster.cluster.master_auth.0.client_certificate_config.0.issue_client_certificate ? google_container_cluster.cluster.master_auth.0.cluster_ca_certificate : ""
}