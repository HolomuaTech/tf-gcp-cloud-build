output "triggers" {
  description = "Map of created Cloud Build triggers"
  value = {
    for k, v in google_cloudbuild_trigger.repo_triggers : k => {
      id          = v.id
      name        = v.name
      description = v.description
    }
  }
}

output "cloudbuild_trigger_sa_email" {
  description = "Email address of the Cloud Build trigger service account"
  value       = google_service_account.cloudbuild_trigger_sa.email
} 