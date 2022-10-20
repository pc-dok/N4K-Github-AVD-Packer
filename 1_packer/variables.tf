# Terraform Cloud Variables - Please ensure RBAC Contributer Settings in this Variables

variable "ARM_CLIENT_ID" {}
variable "ARM_CLIENT_SECRET" {}
variable "ARM_TENANT_ID" {}
variable "ARM_SUBSCRIPTION" {}

# Main
variable "artifacts" {
  type        = string
  default     = "n4k-we-packer-avd-images"
  description = "The location from Azure Ressource"
}

variable "builder" {
  type        = string
  default     = "n4k-we-packer-avd-build"
  description = "The location from Azure Ressource"
}

variable "location" {
  type        = string
  default     = "westeurope"
  description = "The location from Azure Ressource"
}
