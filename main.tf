provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable Cloud Build API and Artifact Registry API
resource "google_project_service" "cloud_build_api" {
  service = "cloudbuild.googleapis.com"
  project = var.project_id
}

resource "google_project_service" "artifact_registry_api" {
  service = "artifactregistry.googleapis.com"
  project = var.project_id
}

# Create a Cloud Build trigger for GitHub repository
resource "google_cloudbuild_trigger" "github_trigger" {
  name = "${var.github_repo}-trigger"

  # GitHub repository settings
  github {
    owner  = var.github_owner
    name   = var.github_repo
    push {
      branch = "^main$"  # Set to your desired branch
    }
  }

  # Specify the location of the cloudbuild.yaml in the repo
  build {
    filename = "cloudbuild.yaml"
  }
}

# IAM binding for Cloud Build service account to push to Artifact Registry
resource "google_project_iam_binding" "cloud_build_artifact_registry_permissions" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"

  members = [
    "serviceAccount:${var.project_id}@cloudbuild.gserviceaccount.com"
  ]
}

# IAM binding for Cloud Build service account to deploy to Cloud Run
resource "google_project_iam_binding" "cloud_build_run_permissions" {
  project = var.project_id
  role    = "roles/run.admin"

  members = [
    "serviceAccount:${var.project_id}@cloudbuild.gserviceaccount.com"
  ]
}

