##############################################################
# environments/dev/main.tf
#
# Entorno "dev": orquesta los tres módulos del laboratorio.
#
# Composición de módulos:
#   log_analytics → container_apps  (workspace_id como input)
#   storage       → container_apps  (storage_endpoint como input)
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

provider "azurerm" {
  features {}
}

# ── Locals ────────────────────────────────────────────────────
locals {
  # Sufijo único por alumno: alias + entorno + hash corto del RG
  # Evita colisiones entre los 34 alumnos en la misma suscripción
  suffix = "${var.owner_alias}-${var.environment}"

  # Nombre del Storage Account: solo minúsculas y números, max 24 chars
  # "st" + alias (max 10) + env (max 4) + hash (6) = max 22 chars
  storage_name = "st${replace(substr(var.owner_alias, 0, 10), "-", "")}${substr(var.environment, 0, 3)}${substr(md5(var.resource_group_name), 0, 6)}"

  # Tags comunes — la política OPA verifica que todos existan
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = var.owner_alias
    CostCenter  = var.cost_center
  }
}

# ── Módulo 1: Log Analytics Workspace ────────────────────────
# Se despliega primero porque container_apps lo necesita
module "log_analytics" {
  source = "../../modules/log-analytics"

  name                = local.suffix
  resource_group_name = var.resource_group_name
  location            = var.location
  retention_days      = 30
  tags                = local.common_tags
}

# ── Módulo 2: Storage Account ─────────────────────────────────
module "storage" {
  source = "../../modules/storage"

  storage_account_name = local.storage_name
  resource_group_name  = var.resource_group_name
  location             = var.location
  tags                 = local.common_tags
}

# ── Módulo 3: Container Apps ──────────────────────────────────
# Recibe outputs de los dos módulos anteriores
module "container_apps" {
  source = "../../modules/container-apps"

  name                       = local.suffix
  resource_group_name        = var.resource_group_name
  location                   = var.location
  environment                = var.environment
  log_analytics_workspace_id = module.log_analytics.workspace_id
  storage_endpoint           = module.storage.primary_blob_endpoint
  container_image            = var.container_image
  container_cpu              = var.container_cpu
  container_memory           = var.container_memory
  min_replicas               = var.min_replicas
  max_replicas               = var.max_replicas
  tags                       = local.common_tags
}
