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