variable "project_id" {
  type        = string
  description = "The GCP project ID."
}

variable "region" {
  type        = string
  description = "The GCP region."
}

variable "github_owner" {
  type        = string
  description = "GitHub repository owner (username or organization)."
}

variable "github_repo" {
  type        = string
  description = "The name of the GitHub repository."
}

variable "terraform_sa_email" {
  type        = string
  description = "The email of the service account to be used by Cloud Build."
}
