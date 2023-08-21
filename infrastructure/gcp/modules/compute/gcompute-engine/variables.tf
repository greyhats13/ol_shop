#Naming Standard
variable "region" {
  type        = string
  description = "GCP region"
}

variable "unit" {
  type        = string
  description = "business unit code"
}

variable "env" {
  type        = string
  description = "stage environment where the infrastructure will be deployed"
}

variable "code" {
  type        = string
  description = "service domain code to use"
}

variable "feature" {
  type        = list(string)
  description = "the name of AWS services feature"
}

# service account arguments
variable "project_id" {
  type        = string
  description = "the project id to use"
}

variable "service_account_role" {
  type        = string
  description = "the service account role to use"
}

# gcloud compute arguments
variable "zone" {
  type        = string
  description = "the zone to use"
}

variable "username" {
  type        = string
  description = "the username to use"
}

variable "machine_type" {
  type        = string
  description = "the machine type to use"
}

variable "disk_size" {
  type        = number
  description = "the disk size to use"
}

variable "disk_type" {
  type        = string
  description = "the disk type to use"
}

variable "tags" {
  type        = list(string)
  description = "the tags to use"
}
  
variable "image" {
  type        = string
  description = "the image to use"
}

variable "network_self_link" {
  type        = string
  description = "the netwnetwork_self_link to use"
}

variable "subnet_self_link" {
  type        = string
  description = "the subnet_slef_link to use"
}

variable "extra_args" {
  type        = map(string)
  description = "the extra_args to use"
}

# google cloud firewal arguments
variable "firewall_rules" {
  type        = map(object({
    protocol = string
    ports    = list(number)
  }))
  description = "the gcf firewall rules to use"
}

variable "source_ranges" {
  type        = list(string)
  description = "the gcf firewall source ranges to use"
}

variable "priority" {
  type        = number
  description = "the gcf firewall priority to use"
}

variable "target_tags" {
  type        = list(string)
  description = "the gcf firewall target tags to use"
}