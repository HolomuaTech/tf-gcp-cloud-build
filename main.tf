provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable Cloud Build API
resource "google_project_service" "cloud_build_api" {
  service = "cloudbuild.googleapis.com"
  project = var.project_id
}

# Grant Cloud Build service account permissions to deploy to Cloud Run
resource "google_project_iam_member" "cloud_build_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${var.cloud_build_sa_email}"
}

# Allow Cloud Build to act as the Cloud Run service account
resource "google_service_account_iam_member" "cloud_build_act_as" {
  service_account_id = var.compute_service_account_id
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.cloud_build_sa_email}"
}

# Create Cloud Build triggers
resource "google_cloudbuild_trigger" "repo_triggers" {
  for_each = var.triggers

  name        = each.value.name
  description = each.value.description
  project     = var.project_id
  location    = "global"

  service_account = "projects/${var.project_id}/serviceAccounts/cloud-run-sa@${var.project_id}.iam.gserviceaccount.com"

  github {
    owner = each.value.github_owner
    name  = each.value.github_repo
    push {
      branch = each.value.branch_pattern
    }
  }

  filename = "cloudbuild.yaml"
}

# ------------------------------
# GCS Bucket Configuration
# ------------------------------
resource "google_storage_bucket" "cloud_build_artifact_bucket" {
  count = length(var.cloud_build_artifact_bucket) > 0 ? 1 : 0

  name          = var.cloud_build_artifact_bucket
  location      = var.region
  project       = var.project_id
  force_destroy = true

  uniform_bucket_level_access = true

  lifecycle_rule {
    action {
      type = "Delete"
    }

    condition {
      age = 365
    }
  }
}

resource "google_storage_bucket_iam_member" "cloud_build_access" {
  count = length(var.cloud_build_artifact_bucket) > 0 ? 1 : 0

  bucket = google_storage_bucket.cloud_build_artifact_bucket[0].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.terraform_sa_email}"
}
