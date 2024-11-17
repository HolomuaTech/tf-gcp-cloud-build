provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable Cloud Build API
resource "google_project_service" "cloud_build_api" {
  service = "cloudbuild.googleapis.com"
  project = var.project_id
}

# IAM binding for terraform-sa to push to Artifact Registry
resource "google_project_iam_binding" "cloud_build_artifact_registry_permissions" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"

  members = [
    "serviceAccount:${var.terraform_sa_email}"
  ]
}

# IAM binding for terraform-sa to act as the compute service account for Cloud Run
resource "google_service_account_iam_binding" "cloud_run_act_as" {
  service_account_id = var.compute_service_account_id
  role               = "roles/iam.serviceAccountUser"

  members = [
    "serviceAccount:${var.terraform_sa_email}"
  ]
}

# IAM binding for terraform-sa to deploy to Cloud Run
resource "google_project_iam_binding" "cloud_build_run_permissions" {
  project = var.project_id
  role    = "roles/run.admin"

  members = [
    "serviceAccount:${var.terraform_sa_email}"
  ]
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
