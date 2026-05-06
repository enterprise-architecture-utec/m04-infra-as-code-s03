output "container_app_url" {
  description = "URL pública de la Container App."
  value       = module.container_apps.container_app_url
}

output "container_app_name" {
  description = "Nombre del Container App creado."
  value       = module.container_apps.container_app_name
}

output "container_environment_name" {
  description = "Nombre del Container Apps Environment."
  value       = module.container_apps.environment_name
}

output "storage_account_name" {
  description = "Nombre de la Storage Account creada."
  value       = module.storage.storage_account_name
}

output "storage_blob_endpoint" {
  description = "Endpoint del servicio de blobs."
  value       = module.storage.primary_blob_endpoint
}

output "log_analytics_workspace" {
  description = "Nombre del Log Analytics Workspace."
  value       = module.log_analytics.workspace_name
}

output "resumen" {
  description = "Resumen de los recursos creados por este alumno."
  value = {
    alumno         = var.owner_alias
    resource_group = var.resource_group_name
    region         = var.location
    app_url        = module.container_apps.container_app_url
    storage        = module.storage.storage_account_name
    log_analytics  = module.log_analytics.workspace_name
  }
}
