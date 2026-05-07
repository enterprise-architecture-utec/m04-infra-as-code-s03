# 🧪 Lab Integrado — Módulos Terraform + Policy as Code en Azure

**Curso:** Arquitectura de Soluciones Multinube  
**Módulo 4, Sesión 3:** Automatización Avanzada y Policy as Code  
**Docente:** Aldo Trucios — UTEC Posgrado  
**Duración total:** ~90 minutos  
**Herramienta:** Terraform + OPA/Conftest  
**Nube:** Microsoft Azure

---

## 🎯 ¿Qué construirás?

Una aplicación containerizada con observabilidad integrada, usando **módulos Terraform reutilizables** y validando la infraestructura con **políticas OPA/Rego** antes de desplegarla.

---

## 🏛️ Arquitectura

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Azure Resource Group  (asignado por el docente — ej: rg-alumno-01)     │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │              Log Analytics Workspace                            │    │
│  │         (observabilidad y logs centralizados)                   │    │
│  │         module "log_analytics"                                  │    │
│  └───────────────────────────┬─────────────────────────────────────┘    │
│                              │ diagnósticos & métricas                  │
│                              ▼                                          │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │           Azure Container Apps Environment                      │    │
│  │                                                                 │    │
│  │   ┌───────────────────────────────────────────────────────┐     │    │
│  │   │          Container App (nginx:alpine)                 │     │    │
│  │   │          CPU: 0.25 vCPU  |  RAM: 0.5 Gi               │     │    │
│  │   │          Réplicas: 1 – 3  (auto-scaling por HTTP)     │     │    │
│  │   │          Puerto expuesto: 80 (acceso externo)         │     │    │
│  │   └───────────────────────────────────────────────────────┘     │    │
│  │         module "container_apps"                                 │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │              Storage Account (Standard_LRS)                     │    │
│  │              Contenedor de blobs: "app-assets"                  │    │
│  │              Acceso público deshabilitado                       │    │
│  │              module "storage"                                   │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

### Flujo de datos

```
Internet → Container App (HTTP:80) → responde directamente
                │
                └──► Storage Account  (assets estáticos, config)
                │
                └──► Log Analytics    (logs, métricas, alertas)
```

### Módulos Terraform

```
environments/dev/main.tf
        │
        ├── module "log_analytics"  →  modules/log-analytics/
        │        outputs: workspace_id, workspace_key
        │
        ├── module "storage"        →  modules/storage/
        │        outputs: storage_account_name, primary_endpoint
        │
        └── module "container_apps" →  modules/container-apps/
                 inputs: workspace_id (de log_analytics)
                 outputs: app_url, app_name
```

---

## 🛡️ Políticas OPA validadas antes del `apply`

| Política | Qué garantiza |
|----------|--------------|
| `azure_required_tags.rego` | Tags `Environment`, `ManagedBy`, `Owner` y `CostCenter` en todos los recursos |
| `azure_storage_secure.rego` | Storage Account sin acceso público y con TLS 1.2 mínimo |
| `azure_container_resources.rego` | CPU ≤ 1.0 vCPU y RAM ≤ 2.0 Gi por contenedor |
| `azure_location.rego` | Solo se permiten las regiones `eastus`, `eastus2` y `westus2` |

---

## 📁 Estructura del Repositorio

```
m04-azure-iac-lab/
│
├── README.md                          ← Este archivo
├── .gitignore
│
├── modules/                           ── Librería de módulos reutilizables
│   ├── log-analytics/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── storage/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── container-apps/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── environments/
│   └── dev/                           ── Entorno que consume los módulos
│       ├── README.md                  ← Instrucciones paso a paso (Fase 2)
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars           ← Aquí cada alumno configura su RG
│
└── policy/                            ── Políticas OPA/Rego
    ├── README.md                      ← Instrucciones paso a paso (Fase 3)
    ├── azure_required_tags.rego
    ├── azure_storage_secure.rego
    ├── azure_container_resources.rego
    └── azure_location.rego
```

---

## ⚙️ Requisitos Previos

| Herramienta | Versión mínima | Instalación |
|-------------|----------------|-------------|
| Terraform | >= 1.5.0 | https://developer.hashicorp.com/terraform/install |
| Azure CLI | >= 2.50 | https://learn.microsoft.com/cli/azure/install-azure-cli |
| conftest | >= 0.45.0 | https://www.conftest.dev/install/ |

```bash
# Verificar instalaciones
terraform version
az version
conftest --version
```

---

## 🔐 Autenticación Azure

```bash
az login
az account set --subscription "<ID_SUSCRIPCION_COMPARTIDA>"

# Verificar que apuntas a la suscripción correcta
az account show --query '{Nombre:name, ID:id}' --output table
```

---

## 👤 Configuración por Alumno

Cada alumno edita **un solo archivo**: `environments/dev/terraform.tfvars`

```hcl
# ── EDITAR ESTOS VALORES ──────────────────────────────────
resource_group_name = "rg-alumno-XX"   # ← Tu RG asignado por el docente
owner_alias         = "alumnoXX"       # ← Tu alias (sin espacios, minúsculas)
# ─────────────────────────────────────────────────────────

# Estos valores son iguales para todos
environment  = "dev"
location     = "eastus"
cost_center  = "CC-UTEC-M04"
```

El `owner_alias` se usa como sufijo en todos los recursos para evitar colisiones:

```
log-analytics-alumno01-dev-xxxxx
st + alumno01 + dev + xxxxx    (storage account, sin guiones)
ca-alumno01-dev-xxxxx          (container app)
```

---

## 🗺️ Flujo del Laboratorio

```
[Fase 1 — 10 min]  Autenticación + configuración de terraform.tfvars

[Fase 2 — 40 min]  Módulos Terraform
    cd environments/dev/
    terraform init
    terraform plan -out=plan.tfplan
    terraform show -json plan.tfplan > plan.json
    terraform apply plan.tfplan

[Fase 3 — 30 min]  Policy as Code
    conftest test plan.json -p ../../policy/   → debe pasar
    (provocar violaciones intencionalmente y observar el bloqueo)
    conftest test plan.json -p ../../policy/ && terraform apply plan.tfplan

[Limpieza — 10 min]
    terraform destroy -auto-approve
```

---

> 🚀 **Comienza por:** [`environments/dev/README.md`](environments/dev/README.md)
