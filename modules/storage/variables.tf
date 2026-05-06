variable "storage_account_name" {
  description = <<-EOT
    Nombre de la Storage Account. Reglas de Azure:
    - Solo letras minúsculas y números
    - Entre 3 y 24 caracteres
    - Globalmente único en Azure
    El entorno genera este nombre con el alias del alumno para evitar colisiones.
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "El nombre solo puede contener letras minúsculas y números (3–24 chars)."
  }
}

variable "resource_group_name" {
  description = "Nombre del Resource Group."
  type        = string
}

variable "location" {
  description = "Región de Azure."
  type        = string
}

variable "tags" {
  description = "Tags a aplicar a los recursos de almacenamiento."
  type        = map(string)
  default     = {}
}
