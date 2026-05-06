# =============================================================
#  terraform.tfvars — Configuración por alumno
#  ⚠️ EDITA SOLO LAS DOS LÍNEAS MARCADAS CON ←
# =============================================================

# ── EDITAR ESTOS VALORES ──────────────────────────────────────
resource_group_name = "rg-alumno-XX"   # ← Tu RG asignado por el docente
owner_alias         = "alumnoXX"       # ← Tu alias único (2-10 chars, sin espacios)
# ─────────────────────────────────────────────────────────────

# Valores comunes para toda la clase (no modificar)
environment      = "dev"
location         = "eastus"
cost_center      = "CC-UTEC-M04"
container_image  = "nginx:alpine"
container_cpu    = 0.25
container_memory = "0.5Gi"
min_replicas     = 1
max_replicas     = 3
