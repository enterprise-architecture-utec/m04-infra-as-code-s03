variable "name" {
  description = "Nombre del Container App (y prefijo del Environment)."
  type        = string
}
variable "location" {
  description = "Región de Azure."
  type        = string
}
variable "resource_group_name" {
  description = "Nombre del Resource Group."
  type        = string
}
variable "environment" {
  description = "Nombre del entorno. Se inyecta como variable de entorno en el contenedor."
  type        = string
}
variable "log_analytics_workspace_id" {
  description = "ID del Log Analytics Workspace al que se enviarán los logs."
  type        = string
}
variable "storage_account_name" {
  description = "Nombre de la Storage Account. Se inyecta como variable de entorno en el contenedor."
  type        = string
}
variable "container_image" {
  description = "Imagen Docker. Formato: imagen:tag"
  type        = string
  default     = "nginx:alpine"
}
variable "cpu" {
  description = "CPU en vCPU. Valores válidos: 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0"
  type        = number
  default     = 0.25
  validation {
    condition     = contains([0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0], var.cpu)
    error_message = "CPU debe ser 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75 o 2.0"
  }
}
variable "memory" {
  description = "Memoria del contenedor. Debe ser el doble del cpu. Ej: 0.25 CPU → '0.5Gi'"
  type        = string
  default     = "0.5Gi"
}
variable "max_replicas" {
  description = "Número máximo de réplicas para autoescalado. La política OPA limita a 5."
  type        = number
  default     = 3
  validation {
    condition     = var.max_replicas >= 1 && var.max_replicas <= 10
    error_message = "max_replicas debe estar entre 1 y 10."
  }
}
variable "tags" {
  description = "Mapa de tags."
  type        = map(string)
  default     = {}
}
