#Naming Standard
variable "region" {
  type        = string
  description = "The GCP region where resources will be created."
}

variable "unit" {
  type        = string
  description = "Business unit code."
}

variable "env" {
  type        = string
  description = "Stage environment where the infrastructure will be deployed."
}

variable "code" {
  type        = string
  description = "Service domain code."
}

variable "feature" {
  type        = list(string)
  description = "Feature names"
}

# subnet arguments
variable "pods_range_name" {
  type        = string
  description = "The name of the pods range."
}

variable "services_range_name" {
  type        = string
  description = "The name of the services range."
}

# router arguments
variable "nat_ip_allocate_option" {
  type        = string
  description = "The way NAT IPs should be allocated. Valid values are AUTO_ONLY, MANUAL_ONLY or AUTO_ONLY."
}

variable "source_subnetwork_ip_ranges_to_nat" {
  type        = string
  description = "The way NAT IPs should be allocated. Valid values are LIST_OF_SUBNETWORKS or ALL_SUBNETWORKS_ALL_IP_RANGES."
}

variable "subnetworks" {
  type        = list(object({
    name                     = string
    source_ip_ranges_to_nat  = list(string)
  }))
  description = "List of subnetworks to configure NAT for."
  default = []
}