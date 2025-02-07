provider "google" {
  project = var.project_id
  region  = var.region
}

# Enable Cloud Build API
resource "google_project_service" "cloud_build_api" {
  service = "cloudbuild.googleapis.com"
  project = var.project_id
}

# Enable Cloud Logging API
resource "google_project_service" "logging_api" {
  service = "logging.googleapis.com"
  project = var.project_id

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Enable Cloud Storage API
resource "google_project_service" "storage_api" {
  service = "storage.googleapis.com"
  project = var.project_id

  disable_dependent_services = false
  disable_on_destroy         = false
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

# Grant Cloud Build service account permissions to write logs
resource "google_project_iam_member" "cloud_build_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${var.cloud_build_sa_email}"
}

# Grant Cloud Build service account builder permissions
resource "google_project_iam_member" "cloud_build_builder" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${var.cloud_build_sa_email}"
}

# Grant Cloud Build service account permissions to push/pull from Artifact Registry
resource "google_project_iam_member" "cloud_build_artifact_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${var.cloud_build_sa_email}"
}

# Grant Cloud Build service account permissions to push/pull from shared Artifact Registry
resource "google_project_iam_member" "cloud_build_shared_artifact_registry" {
  project = var.shared_project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${var.cloud_build_sa_email}"
}

# Grant Cloud Run service account permissions to write logs
resource "google_project_iam_member" "cloud_run_sa_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:cloud-run-sa@${var.project_id}.iam.gserviceaccount.com"
}

# Grant Cloud Run service account permissions to push/pull from shared Artifact Registry
resource "google_project_iam_member" "cloud_run_sa_shared_artifact_registry" {
  project = var.shared_project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:cloud-run-sa@${var.project_id}.iam.gserviceaccount.com"
}

# Grant Cloud Run service account permissions to deploy to Cloud Run
resource "google_project_iam_member" "cloud_run_sa_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:cloud-run-sa@${var.project_id}.iam.gserviceaccount.com"
}

# Allow Cloud Run service account to act as the default Compute service account
resource "google_service_account_iam_member" "cloud_run_sa_act_as_compute" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.project_number}-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:cloud-run-sa@${var.project_id}.iam.gserviceaccount.com"
}

# Grant Cloud Run Service Agent permissions to pull from shared Artifact Registry
resource "google_project_iam_member" "cloud_run_agent_shared_artifact_registry" {
  project = var.shared_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:service-${var.project_number}@serverless-robot-prod.iam.gserviceaccount.com"
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

# Create a storage bucket for Cloud Build logs
resource "google_storage_bucket" "cloud_build_logs" {
  project  = var.project_id
  name     = "${var.project_id}-cloud-build-logs"
  location = var.region

  uniform_bucket_level_access = true
  force_destroy              = true

  lifecycle_rule {
    condition {
      age = 30  # days
    }
    action {
      type = "Delete"
    }
  }
}

# Grant Cloud Build service account access to write logs to the bucket
resource "google_storage_bucket_iam_member" "cloud_build_logs_writer" {
  bucket = google_storage_bucket.cloud_build_logs.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${var.cloud_build_sa_email}"
}

# Grant Cloud Run service account access to write logs to the bucket
resource "google_storage_bucket_iam_member" "cloud_run_sa_logs_writer" {
  bucket = google_storage_bucket.cloud_build_logs.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:cloud-run-sa@${var.project_id}.iam.gserviceaccount.com"
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
