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

variable "artifact_registry" {
  description = "Artifact Registry configuration"
  type = object({
    project_id    = string # shared-resources project
    location      = string
    repository_id = string
  })
}

variable "microservices" {
  type = list(object({
    name        = string
    dockerfile  = string
    context_dir = string
    repo_name   = string
    branch      = string
  }))
  description = "List of microservices to configure build triggers for"
}

variable "cloudbuild_service_account_email" {
  description = "Email of the Cloud Build service account"
  type        = string
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
}

variable "grant_build_editor_role" {
  description = "Whether to grant the Cloud Build Editor role to the Cloud Build service account"
  type        = bool
  default     = true
} 