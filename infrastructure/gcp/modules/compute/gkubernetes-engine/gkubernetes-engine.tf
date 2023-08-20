# Create a GKE cluster with 2 node pools
resource "google_container_cluster" "cluster" {
  # Define the cluster name using variables
  name             = "${var.unit}-${var.env}-${var.code}-${var.feature}"
  # Set the location based on environment and autopilot settings
  location         = var.env == "dev" && !var.enable_autopilot ? "${var.region}-a" : var.region
  # Enable autopilot if the variable is set, otherwise set to null
  enable_autopilot = !var.enable_autopilot ? null : true
  # Configure cluster autoscaling if autopilot is not enabled
  dynamic "cluster_autoscaling" {
    for_each = var.enable_autopilot ? [] : [1]
    content {
      enabled = var.cluster_autoscaling.enabled
      # Define resource limits for autoscaling
      dynamic "resource_limits" {
        for_each = var.cluster_autoscaling.resource_limits
        content {
          resource_type = resource_limits.key
          minimum       = resource_limits.value.minimum
          maximum       = resource_limits.value.maximum
        }
      }
    }
  }
  # Remove the default node pool if not in autopilot mode
  remove_default_node_pool = !var.enable_autopilot ? true : null
  initial_node_count       = 1
  # Configure master authentication with client certificate
  master_auth {
    client_certificate_config {
      issue_client_certificate = var.issue_client_certificate
    }
  }
  # Configure private cluster settings based on variables
  dynamic "private_cluster_config" {
    for_each = var.private_cluster_config[var.env].enable_private_endpoint || var.private_cluster_config[var.env].enable_private_nodes ? [1] : []
    content {
      enable_private_endpoint = var.private_cluster_config[var.env].enable_private_endpoint
      enable_private_nodes    = var.private_cluster_config[var.env].enable_private_nodes
      master_ipv4_cidr_block  = var.private_cluster_config[var.env].master_ipv4_cidr_block
    }
  }
  # Set binary authorization mode
  binary_authorization {
    evaluation_mode = var.binary_authorization.evaluation_mode
  }
  # Configure network policy if not in autopilot mode and enabled
  dynamic "network_policy" {
    for_each = !var.enable_autopilot && var.network_policy.enabled ? [1] : []
    content {
      enabled  = var.network_policy.enabled
      provider = var.network_policy.provider
    }
  }
  # Set datapath provider (Dataplane V2), incompatible with network policy
  datapath_provider = var.datapath_provider
  # Define authorized networks for master access
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "182.253.194.32/28"
      display_name = "my-home-public-ip"
    }
  }
  # Define IP allocation policy for cluster and services
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }
  # Set network and subnetwork links
  network    = var.vpc_self_link
  subnetwork = var.subnet_self_link
  # Configure DNS settings based on variables
  dynamic "dns_config" {
    for_each = var.dns_config[var.env].cluster_dns != null ? [1] : []
    content {
      cluster_dns        = var.dns_config[var.env].cluster_dns
      cluster_dns_scope  = var.dns_config[var.env].cluster_dns_scope
      cluster_dns_domain = var.dns_config[var.env].cluster_dns_domain
    }
  }
  # Define resource labels for the cluster
  resource_labels = {
    business_unit = var.unit
    environment   = var.env
    code          = var.code
    feature       = var.feature
  }
}

# Define local variable for node configuration based on environment
locals {
  node_config = var.env == "dev" ? { spot = var.node_config["spot"] } : var.node_config
}

# Create an on-demand node pool
resource "google_container_node_pool" "nodepool" {
  for_each   = !var.enable_autopilot ? local.node_config: {}
  name       = each.key
  location   = var.env == "dev" && !var.enable_autopilot ? "${var.region}-a" : var.region
  cluster    = google_container_cluster.cluster.name
  node_count = var.env == "dev" ? 2 : each.value.node_count

  # Define node configuration settings based on environment and variables
  node_config {
    machine_type = var.env == "dev" ? each.value.machine_type["dev"] : (
      var.env == "stg" ? each.value.machine_type["stg"] : each.value.machine_type["prd"]
    )
    disk_size_gb    = each.value.disk_size_gb
    disk_type       = var.env == "dev" ? each.value.disk_type[0] : each.value.disk_type[1]
    service_account = each.value.service_account
    oauth_scopes    = each.value.oauth_scopes
    tags            = each.value.tags
    # Configure shielded instance settings if secure boot is enabled
    dynamic "shielded_instance_config" {
      for_each = each.value.shielded_instance_config.enable_secure_boot ? [1] : []
      content {
        enable_secure_boot          = each.value.shielded_instance_config.enable_secure_boot
        enable_integrity_monitoring = each.value.shielded_instance_config.enable_integrity_monitoring
      }
    }
    # Define node labels
    labels = {
      name          = "${var.unit}-${var.env}-${var.code}-${var.feature}-nodepool-${each.key}"
      business_unit = var.unit
      environment   = var.env
      code          = var.code
      feature       = var.feature
      type          = each.key
    }
  }

  # Configure node management settings for auto repair and upgrade
  dynamic "management" {
    for_each = var.node_management.auto_repair || var.node_management.auto_upgrade ? [1] : []
    content {
      auto_repair  = var.node_management.auto_repair
      auto_upgrade = var.node_management.auto_upgrade
    }
  }

  # Configure autoscaling settings for spot instances
  dynamic "autoscaling" {
    for_each = each.key == "spot" ? [1] : []
    content {
      min_node_count = var.env == "dev" ? 2 : each.value.node_count
      max_node_count = each.value.max_node_count
    }
  }
}

# Workaround for a known bug (https://github.com/hashicorp/terraform-provider-kubernetes/issues/1424)
data "google_client_config" "current" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.cluster.endpoint}"
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.cluster.master_auth.0.cluster_ca_certificate)
}

# Define cluster role binding for client cluster admin
resource "kubernetes_cluster_role_binding" "client_cluster_admin" {
  metadata {
    annotations = {}
    labels      = {}
    name        = "client-cluster-admin"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  # Define subjects for the role binding
  subject {
    kind      = "User"
    name      = "client"
    api_group = "rbac.authorization.k8s.io"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = "kube-system"
  }
  subject {
    kind      = "Group"
    name      = "system:masters"
    api_group = "rbac.authorization.k8s.io"
  }
}
