# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",  # Needed for GitHub integration
    "iam.googleapis.com",           # Added to ensure IAM API is enabled
    "run.googleapis.com",           # Added for Cloud Run deployments
    "artifactregistry.googleapis.com" # Added for container image management
  ])

  project = var.project_id
  service = each.key

  disable_on_destroy = false
}

# Get project data for service account
data "google_project" "project" {
  project_id = var.project_id
}

# Grant project-specific permissions to Cloud Build service account
resource "google_project_iam_member" "cloudbuild_project_roles" {
  for_each = toset(concat([
    # Base roles needed for Cloud Build operations
    "roles/cloudbuild.builds.editor",  # Needed for creating and managing builds
    "roles/cloudbuild.builds.builder", # Needed for running builds
    "roles/iam.serviceAccountUser",    # Needed for accessing service accounts
    "roles/run.admin",                 # Needed for deploying to Cloud Run
    "roles/storage.admin",             # Needed for accessing build artifacts and Cloud Storage
    "roles/logging.logWriter",         # Needed for writing build logs
    "roles/artifactregistry.reader"    # Needed for pulling base images
  ], var.additional_cloudbuild_roles))  # Additional roles specified by the application

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

# Grant service agent roles to the appropriate service accounts
resource "google_project_iam_member" "service_agent_roles" {
  for_each = {
    "roles/run.serviceAgent" = "serviceAccount:service-${data.google_project.project.number}@serverless-robot-prod.iam.gserviceaccount.com",
    "roles/cloudbuild.serviceAgent" = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"
  }

  project = var.project_id
  role    = each.key
  member  = each.value
}

# Create a dedicated service account for Cloud Build triggers
resource "google_service_account" "cloudbuild_trigger_sa" {
  project      = var.project_id
  account_id   = "${var.app_name}-${var.environment}-cloudbuild-sa"
  display_name = "Cloud Build Trigger Service Account for ${var.app_name} (${var.environment})"
  description  = "Service account used by Cloud Build triggers for ${var.app_name} in ${var.environment} environment"
}

# Grant necessary roles to the dedicated service account
resource "google_project_iam_member" "cloudbuild_trigger_sa_roles" {
  for_each = toset([
    "roles/cloudbuild.builds.builder",
    "roles/cloudbuild.builds.editor",
    "roles/iam.serviceAccountUser",
    "roles/run.admin",
    "roles/storage.admin",
    "roles/logging.logWriter",
    "roles/artifactregistry.reader"
  ])

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.cloudbuild_trigger_sa.email}"
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

  depends_on = [
    google_project_service.required_apis,
    google_project_iam_member.cloudbuild_project_roles,
    google_project_iam_member.service_agent_roles,
    google_project_iam_member.cloudbuild_trigger_sa_roles
  ]
}
