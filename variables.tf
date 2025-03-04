variable "project_id" {
  description = "The GCP Project ID where the Cloud Build triggers will be created"
  type        = string
}

variable "region" {
  description = "The region for Cloud Build resources"
  type        = string
}

variable "app_name" {
  description = "The name of the application (e.g., 'demo', 'belay')"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., 'dev', 'prod')"
  type        = string
}

variable "location" {
  description = "The location for the Cloud Build triggers"
  type        = string
  default     = "global"
}

variable "additional_cloudbuild_roles" {
  description = "Additional IAM roles to grant to Cloud Build service account"
  type        = list(string)
  default     = []
}

variable "included_files" {
  description = "List of file patterns to trigger builds on"
  type        = list(string)
  default     = ["**"]
}

variable "cloudbuild_filename" {
  description = "Name of the Cloud Build configuration file"
  type        = string
  default     = "cloudbuild.yaml"
}

variable "shared_artifact_registry_project" {
  description = "The GCP Project ID where the shared Artifact Registry exists"
  type        = string
  default     = ""
}

variable "shared_artifact_registry_location" {
  description = "The location of the shared Artifact Registry"
  type        = string
  default     = "us-west1"
}

variable "shared_artifact_registry_name" {
  description = "The name of the shared Artifact Registry repository"
  type        = string
  default     = "shared-container-registry"
}

variable "triggers" {
  description = "Map of Cloud Build triggers to create"
  type = map(object({
    name           = string
    description    = string
    github_owner   = string
    github_repo    = string
    branch_pattern = string
    substitutions  = optional(map(string), {})
  }))
}

variable "manage_project_permissions" {
  description = "Whether this environment should manage project-level permissions"
  type        = bool
  default     = false
}

variable "shared_repository_name" {
  description = "Name of the shared Artifact Registry repository"
  type        = string
  default     = "shared-container-registry"
}

variable "service_account_id" {
  description = "Custom service account ID to use for Cloud Build (defaults to {app_name}-{environment}-cloudbuild-sa)"
  type        = string
  default     = ""
}

variable "logging" {
  description = "Logging option for Cloud Build triggers (CLOUD_LOGGING_ONLY, GCS_ONLY, or NONE)"
  type        = string
  default     = "CLOUD_LOGGING_ONLY"
} 