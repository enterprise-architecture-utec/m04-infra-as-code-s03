output "container_app_id" {
  description = "ID del recurso Container App."
  value       = azurerm_container_app.this.id
}
output "container_app_name" {
  description = "Nombre del Container App."
  value       = azurerm_container_app.this.name
}
output "container_app_fqdn" {
  description = "FQDN público del Container App."
  value       = azurerm_container_app.this.ingress[0].fqdn
}
output "container_app_url" {
  description = "URL completa del Container App."
  value       = "https://${azurerm_container_app.this.ingress[0].fqdn}"
}
output "environment_id" {
  description = "ID del Container Apps Environment."
  value       = azurerm_container_app_environment.this.id
}
output "environment_name" {
  description = "Nombre del Container Apps Environment."
  value       = azurerm_container_app_environment.this.name
}
