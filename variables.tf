variable "project_id" {
  type        = string
  description = "The GCP project ID."
}

variable "region" {
  type        = string
  description = "The GCP region."
}

variable "cloud_build_sa_email" {
  type        = string
  description = "Email of the Cloud Build service account"
}

variable "compute_service_account_id" {
  type        = string
  description = "The service account ID for Compute Engine or Cloud Run to use."
}

variable "cloud_build_artifact_bucket" {
  type        = string
  default     = ""
  description = "The name of a bucket to create for storing Cloud Build artifacts."
}

variable "triggers" {
  description = "Map of Cloud Build triggers to create"
  type = map(object({
    name           = string
    description    = string
    github_owner   = string
    github_repo    = string
    branch_pattern = string
  }))
  default = {}
}

variable "terraform_sa_email" {
  type        = string
  description = "Email of the Terraform service account"
}
