variable "name" {
  description = "Sufijo único para el nombre del workspace (incluye alias del alumno)."
  type        = string
}

variable "resource_group_name" {
  description = "Nombre del Resource Group donde se creará el workspace."
  type        = string
}

variable "location" {
  description = "Región de Azure."
  type        = string
}

variable "retention_days" {
  description = "Días de retención de logs (30–730)."
  type        = number
  default     = 30

  validation {
    condition     = var.retention_days >= 30 && var.retention_days <= 730
    error_message = "retention_days debe estar entre 30 y 730."
  }
}

variable "tags" {
  description = "Tags a aplicar al workspace."
  type        = map(string)
  default     = {}
}
