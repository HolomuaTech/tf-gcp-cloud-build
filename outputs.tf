output "cloud_build_service_account" {
  value = "serviceAccount:${var.project_id}@cloudbuild.gserviceaccount.com"
}

