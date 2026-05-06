##############################################################
# modules/storage/main.tf
#
# Módulo reutilizable: Storage Account + Blob Container
# Almacena assets estáticos de la aplicación.
# Configurado de forma segura: sin acceso público, TLS 1.2+.
##############################################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90"
    }
  }
}

# Storage Account — nombre sin guiones, máximo 24 chars, minúsculas
resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # Seguridad: política requerida por aws_storage_secure.rego
  min_tls_version           = "TLS1_2"
  allow_nested_items_to_be_public = false
  https_traffic_only_enabled      = true

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

# Blob container para assets de la aplicación
resource "azurerm_storage_container" "app_assets" {
  name                  = "app-assets"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"   # Sin acceso público
}
