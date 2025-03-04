# Get project data for service account
data "google_project" "project" {
  project_id = var.project_id
}

# Create environment-specific service account for Cloud Build triggers
resource "google_service_account" "cloudbuild_trigger_sa" {
  project      = var.project_id
  account_id   = var.service_account_id != "" ? var.service_account_id : "${var.app_name}-${var.environment}-cloudbuild-sa"
  display_name = "Cloud Build Service Account for ${var.app_name} ${var.environment}"
  description  = "Service account used by Cloud Build triggers for ${var.app_name} in ${var.environment} environment"
}

# Grant necessary permissions to the environment-specific service account
resource "google_project_iam_member" "cloudbuild_trigger_sa_permissions" {
  for_each = toset([
    "roles/cloudbuild.builds.builder",
    "roles/cloudbuild.serviceAgent",
    "roles/serviceusage.serviceUsageConsumer",
    "roles/iam.serviceAccountUser",
    "roles/cloudbuild.builds.editor",
    "roles/viewer",
    "roles/run.admin"
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.cloudbuild_trigger_sa.email}"
}

# Grant permissions to Cloud Build service account in shared Artifact Registry
resource "google_artifact_registry_repository_iam_member" "shared_repository_permissions" {
  count = var.shared_artifact_registry_project != "" ? 1 : 0

  project    = var.shared_artifact_registry_project
  location   = var.shared_artifact_registry_location
  repository = var.shared_artifact_registry_name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.cloudbuild_trigger_sa.email}"
}

# Create Cloud Build trigger for each repository
resource "google_cloudbuild_trigger" "repo_triggers" {
  for_each = var.triggers

  project     = var.project_id
  name        = each.value.name
  description = each.value.description
  location    = var.location

  service_account = google_service_account.cloudbuild_trigger_sa.id

  github {
    owner = each.value.github_owner
    name  = each.value.github_repo
    push {
      branch = each.value.branch_pattern
    }
  }

  included_files = var.included_files
  filename       = var.cloudbuild_filename
  
  substitutions = merge(
    {
      "_PROJECT_ID" = var.project_id
      "_REGION"     = var.region
    },
    lookup(each.value, "substitutions", {})
  )
}
