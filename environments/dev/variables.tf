# ── Variables de identidad del alumno ─────────────────────────

variable "resource_group_name" {
  description = <<-EOT
    Nombre del Resource Group asignado por el docente.
    Ejemplo: "rg-alumno-01", "rg-alumno-02", ...
    Cada alumno tiene su propio Resource Group en la suscripción compartida.
  EOT
  type        = string
}

variable "owner_alias" {
  description = <<-EOT
    Alias único del alumno, sin espacios, en minúsculas.
    Se usa como sufijo en todos los recursos para evitar colisiones.
    Ejemplo: "jperez", "mgarcia", "alumno01"
    Máximo 10 caracteres.
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.owner_alias))
    error_message = "owner_alias solo puede contener letras minúsculas y números (2–10 chars)."
  }
}

# ── Variables comunes ─────────────────────────────────────────

variable "environment" {
  description = "Nombre del entorno."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "El entorno debe ser dev, stg o prod."
  }
}

variable "location" {
  description = "Región de Azure. La política OPA permite: eastus, eastus2, westus2."
  type        = string
  default     = "eastus"
}

variable "cost_center" {
  description = "Centro de costos para el tag CostCenter (requerido por política OPA)."
  type        = string
  default     = "CC-UTEC-M04"
}

# ── Variables del Container App ───────────────────────────────

variable "container_image" {
  description = "Imagen Docker del contenedor. Por defecto nginx:alpine."
  type        = string
  default     = "nginx:alpine"
}

variable "container_cpu" {
  description = "CPU en vCPU asignada al contenedor. La política OPA limita a <= 1.0."
  type        = number
  default     = 0.25
}

variable "container_memory" {
  description = "Memoria asignada al contenedor. La política OPA limita a <= 2.0Gi."
  type        = string
  default     = "0.5Gi"
}

variable "min_replicas" {
  description = "Réplicas mínimas del contenedor."
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Réplicas máximas del contenedor (auto-scaling)."
  type        = number
  default     = 3
}
