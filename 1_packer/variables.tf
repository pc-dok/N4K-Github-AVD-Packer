# Terraform Cloud Variables - Please ensure RBAC Contributer Settings in this Variables

variable "ARM_CLIENT_ID" {}
variable "ARM_CLIENT_SECRET" {}
variable "ARM_TENANT_ID" {}
variable "ARM_SUBSCRIPTION" {}
variable "GITHUB_SECRET" {}
variable "GITHUB_OWNER" {}

# Terraform Workspace Login

variable "tf-org" {
  type        = string
  default     = "N4K"
  description = "The Organisation Name in your Terraform Cloud Workspace"
}

variable "tf-ws-github" {
  type        = string
  default     = "1_Github-AVD-Packer"
  description = "The Workspace for Github"
}

variable "tf-ws-aadds" {
  type        = string
  default     = "2_Github-AVD-AADDS"
  description = "The Workspace for AADDS"
}

variable "tf-ws-bastion" {
  type        = string
  default     = "3_Github-AVD-Bastion"
  description = "The Workspace for Bastion"
}

variable "tf-ws-avd" {
  type        = string
  default     = "4_Github-AVD-WVD"
  description = "The Workspace for AVD"
}

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
