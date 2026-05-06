output "workspace_id" {
  description = "ID del Log Analytics Workspace. Requerido por Container Apps Environment."
  value       = azurerm_log_analytics_workspace.this.id
}

output "workspace_customer_id" {
  description = "Customer ID (GUID) del workspace. Requerido por Container Apps Environment."
  value       = azurerm_log_analytics_workspace.this.workspace_id
}

output "primary_shared_key" {
  description = "Clave primaria del workspace. Requerida por Container Apps Environment."
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive   = true
}

output "workspace_name" {
  description = "Nombre del Log Analytics Workspace creado."
  value       = azurerm_log_analytics_workspace.this.name
}
