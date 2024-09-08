provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable Cloud Build API and Artifact Registry API
resource "google_project_service" "cloud_build_api" {
  service = "cloudbuild.googleapis.com"
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
      branch = "^main$"
    }
  }

  # Define the build steps in-line (instead of using cloudbuild.yaml)
  build {
    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["build", "-t", "us-west1-docker.pkg.dev/${var.project_id}/demo-app-docker-repo/nginx-hello-world", "."]
    }

    step {
      name = "gcr.io/cloud-builders/docker"
      args = ["push", "us-west1-docker.pkg.dev/${var.project_id}/demo-app-docker-repo/nginx-hello-world"]
    }

    step {
      name = "gcr.io/google.com/cloudsdktool/cloud-sdk"
      entrypoint = "gcloud"
      args = [
        "run", "deploy", "nginx-hello-world",
        "--image", "us-west1-docker.pkg.dev/${var.project_id}/demo-app-docker-repo/nginx-hello-world",
        "--region", var.region,
        "--platform", "managed",
        "--allow-unauthenticated"
      ]
    }
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

