variable "project_id" {
  type        = string
  description = "The GCP project ID."
}

variable "region" {
  type        = string
  description = "The GCP region."
}

variable "terraform_sa_email" {
  type        = string
  description = "The email of the service account to be used by Cloud Build."
}

variable "compute_service_account_id" {
  type        = string
  description = "The service account ID for Compute Engine or Cloud Run to use."
}
