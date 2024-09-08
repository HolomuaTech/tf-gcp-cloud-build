output "cloud_build_trigger_name" {
  value = google_cloudbuild_trigger.github_trigger.name
}

output "cloud_build_service_account" {
  value = "serviceAccount:${var.project_id}@cloudbuild.gserviceaccount.com"
}

