output "storage_account_name" {
  description = "Nombre de la Storage Account creada."
  value       = azurerm_storage_account.this.name
}

output "storage_account_id" {
  description = "ID de la Storage Account."
  value       = azurerm_storage_account.this.id
}

output "primary_blob_endpoint" {
  description = "Endpoint primario del servicio de blobs."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "container_name" {
  description = "Nombre del blob container creado."
  value       = azurerm_storage_container.app_assets.name
}
