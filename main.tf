# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "cloudbuild.googleapis.com"
  ])

  project = var.project_id
  service = each.key

  disable_on_destroy = false
}

# Grant Cloud Build editor role to the Cloud Build service account
resource "google_project_iam_member" "cloudbuild_editor" {
  count = var.grant_build_editor_role ? 1 : 0

  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${var.cloudbuild_service_account_email}"
}

# Grant Cloud Build permissions to push to Artifact Registry
resource "google_project_iam_member" "cloudbuild_artifactregistry" {
  count = var.artifact_registry != null ? 1 : 0

  project = var.artifact_registry.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${var.cloudbuild_service_account_email}"
}

# Create Cloud Build trigger for each repository
resource "google_cloudbuild_trigger" "repo_triggers" {
  for_each = var.triggers

  name        = each.value.name
  description = each.value.description
  project     = var.project_id
  location    = "global"

  github {
    owner = each.value.github_owner
    name  = each.value.github_repo
    push {
      branch = each.value.branch_pattern
    }
  }

  included_files = ["**"]
  filename = "cloudbuild.yaml"
} 