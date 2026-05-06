# 🏗️ Fase 2 — Módulos Terraform en Azure

**Tiempo estimado:** 40 minutos  
**Directorio de trabajo:** `environments/dev/`

---

## 🎯 Qué harás en esta fase

Desplegarás **tres recursos Azure** consumiendo módulos Terraform locales. Verás cómo los outputs de un módulo alimentan los inputs de otro (composición de módulos).

```
module "log_analytics"
    │
    └─ workspace_id ──────────────────────► module "container_apps"
                                                     ▲
module "storage"                                     │
    │                                                │
    └─ primary_blob_endpoint ────────────────────────┘
```

---

## 🚀 Pasos

### Paso 0 — Autenticación Azure

```bash
az login
az account set --subscription "<ID_PROPORCIONADO_POR_EL_DOCENTE>"
az account show --query '{Nombre:name, ID:id}' --output table
```

### Paso 1 — Configurar tus parámetros

Abre `terraform.tfvars` y edita **solo estas dos líneas**:

```hcl
resource_group_name = "rg-alumno-XX"   # ← Tu RG asignado (ej: rg-alumno-05)
owner_alias         = "alumnoXX"       # ← Tu alias único  (ej: alumno05)
```

> ⚠️ El `owner_alias` se incluye en el nombre de todos los recursos para evitar colisiones entre los 34 alumnos en la misma suscripción.

Verifica que tu RG existe:

```bash
az group show --name rg-alumno-XX --query '{Nombre:name, Region:location}'
```

### Paso 2 — Explorar la composición de módulos en main.tf

Abre `main.tf` y observa este patrón:

```hcl
module "container_apps" {
  ...
  log_analytics_workspace_id = module.log_analytics.workspace_id    # output → input
  storage_endpoint           = module.storage.primary_blob_endpoint  # output → input
}
```

Cada módulo es una caja negra con interfaz clara: variables de entrada y outputs de salida.

### Paso 3 — Inicializar Terraform

```bash
cd environments/dev/
terraform init
```

Verás los tres módulos inicializados:
```
Initializing modules...
- container_apps in ../../modules/container-apps
- log_analytics  in ../../modules/log-analytics
- storage        in ../../modules/storage
```

### Paso 4 — Generar el plan y exportar a JSON

```bash
terraform plan -out=plan.tfplan
terraform show -json plan.tfplan > plan.json
echo "✅ plan.json generado"
```

Observa los 5 recursos agrupados en 3 módulos en la salida del plan.

### Paso 5 — Validar políticas OPA (preview)

```bash
conftest test plan.json -p ../../policy/
```

Si todo está bien configurado, verás 4 políticas en PASS.

### Paso 6 — Aplicar la infraestructura

```bash
terraform apply plan.tfplan
```

> ⏱️ El Container Apps Environment tarda ~3 minutos en aprovisionarse.

### Paso 7 — Verificar y acceder a la app

```bash
terraform output

# Probar la app
curl $(terraform output -raw container_app_url)
```

Abre la URL en tu navegador — deberías ver la página de Nginx.

### Paso 8 — Explorar el state

```bash
terraform state list
terraform state show module.container_apps.azurerm_container_app.this
terraform plan -refresh-only   # Detectar drift
```

### Paso 9 — Verificar en Azure CLI

```bash
az resource list \
  --resource-group rg-alumno-XX \
  --query '[*].{Nombre:name, Tipo:type}' \
  --output table
```

---

## 🔍 Conceptos practicados

| Concepto | Descripción |
|----------|-------------|
| **Módulo local** | `source = "../../modules/log-analytics"` |
| **Composición de módulos** | Output de un módulo → Input de otro |
| **locals** | Sufijo único por alumno para evitar colisiones |
| **`terraform plan -out`** | Guardar el plan para aplicarlo o analizarlo con OPA |
| **`terraform state list`** | Inspección del state |

---

## ➡️ Siguiente paso

Con el `plan.json` generado, continúa en [`../../policy/README.md`](../../policy/README.md)

---

## 🧹 Limpieza (al finalizar el laboratorio)

```bash
terraform destroy -auto-approve
```
