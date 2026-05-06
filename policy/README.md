# 🛡️ Fase 3 — Policy as Code con OPA y Conftest

**Tiempo estimado:** 30 minutos  
**Directorio:** `policy/`  
**Prerrequisito:** Haber generado `plan.json` en la Fase 2 (Paso 4)

---

## 🎯 Objetivo

Validar el plan de Terraform con **cuatro políticas OPA/Rego** antes de ejecutar `terraform apply`. Si alguna política falla, el despliegue se bloquea. Este es el patrón **shift-left**: detectar violaciones de gobernanza antes de que lleguen a la infraestructura real.

```
terraform plan → plan.json → conftest test → ✅ PASS → terraform apply
                                           → ❌ FAIL → bloqueo (corregir y repetir)
```

---

## 📄 Políticas del laboratorio

| Archivo | Qué valida | Por qué importa |
|---------|-----------|-----------------|
| `azure_required_tags.rego` | Tags `Environment`, `ManagedBy`, `Owner`, `CostCenter` | Rastreabilidad y costos en suscripción compartida |
| `azure_storage_secure.rego` | Sin acceso público, TLS 1.2+, solo HTTPS | Seguridad de los datos almacenados |
| `azure_container_resources.rego` | CPU ≤ 1.0, RAM ≤ 2Gi, réplicas ≤ 5 | Evitar over-provisioning en el entorno de clase |
| `azure_location.rego` | Solo `eastus`, `eastus2`, `westus2` | Residencia de datos y control de costos |

---

## 🚀 Pasos

### Paso 1 — Instalar conftest

```bash
# macOS
brew install conftest

# Linux (64-bit)
sudo wget https://github.com/open-policy-agent/conftest/releases/download/v0.49.0/conftest_0.49.0_Linux_x86_64.tar.gz
sudo tar -xzf conftest_0.49.0_Linux_x86_64.tar.gz
sudo mv conftest /usr/local/bin/

# Windows (Chocolatey)
choco install conftest

# Verificar
conftest --version
```

### Paso 2 — Leer una política Rego antes de ejecutarla

Abre `azure_location.rego` y lee la política:

```rego
package main

allowed_locations := {"eastus", "eastus2", "westus2"}

deny contains msg if {
    resource := input.resource_changes[_]   # iterar sobre cada recurso del plan
    location := resource.change.after.location
    not allowed_locations[location]          # si la región NO está en la lista
    msg := sprintf("❌ ...")                 # producir mensaje de error
}
```

**Clave:** la función `deny` es una colección. Si retorna al menos un mensaje, la política falla (`FAIL`). Si retorna vacía, pasa (`PASS`).

### Paso 3 — Ejecutar TODAS las políticas (escenario PASS)

Con la configuración por defecto (`eastus`, tags correctos, `cpu=0.25`, storage seguro):

```bash
cd environments/dev/
conftest test plan.json -p ../../policy/
```

Resultado esperado:

```
PASS - plan.json - data.main.deny is undefined
PASS - plan.json - data.main.deny is undefined
PASS - plan.json - data.main.deny is undefined
PASS - plan.json - data.main.deny is undefined

4 tests, 4 passed, 0 warnings, 0 failures
```

### Paso 4 — Provocar violaciones intencionalmente (escenario FAIL)

Practica rompiendo cada política para entender cómo funciona el bloqueo.

---

#### 4a — Violación de región (azure_location.rego)

Edita `terraform.tfvars`:
```hcl
location = "brazilsouth"   # ← región no permitida
```

```bash
terraform plan -out=plan.tfplan
terraform show -json plan.tfplan > plan.json
conftest test plan.json -p ../../policy/
```

Verás:
```
FAIL - plan.json - main - ❌ [location] '...' usa la región 'brazilsouth'. Regiones permitidas: {"eastus", "eastus2", "westus2"}
```

**Revierte:** `location = "eastus"`

---

#### 4b — Violación de recursos del contenedor (azure_container_resources.rego)

Edita `terraform.tfvars`:
```hcl
container_cpu    = 1.5    # ← excede el límite de 1.0
container_memory = "4Gi"  # ← excede el límite de 2Gi
```

```bash
terraform plan -out=plan.tfplan && terraform show -json plan.tfplan > plan.json
conftest test plan.json -p ../../policy/
```

**Revierte:**
```hcl
container_cpu    = 0.25
container_memory = "0.5Gi"
```

---

#### 4c — Violación de tags (azure_required_tags.rego)

Edita `environments/dev/main.tf` y elimina el tag `Owner` de `common_tags`:

```hcl
common_tags = {
  Environment = var.environment
  ManagedBy   = "Terraform"
  # Owner     = var.owner_alias   ← comenta esta línea
  CostCenter  = var.cost_center
}
```

```bash
terraform plan -out=plan.tfplan && terraform show -json plan.tfplan > plan.json
conftest test plan.json -p ../../policy/
```

**Revierte:** descomenta la línea del tag `Owner`.

---

#### 4d — Violación de seguridad en Storage (azure_storage_secure.rego)

Edita `modules/storage/main.tf` y cambia:

```hcl
allow_nested_items_to_be_public = true   # ← activa acceso público
```

```bash
terraform plan -out=plan.tfplan && terraform show -json plan.tfplan > plan.json
conftest test plan.json -p ../../policy/
```

**Revierte:** `allow_nested_items_to_be_public = false`

---

### Paso 5 — Ejecutar una sola política

```bash
# Solo la política de región
conftest test plan.json -p ../../policy/azure_location.rego

# Solo la política de storage
conftest test plan.json -p ../../policy/azure_storage_secure.rego
```

### Paso 6 — Ver el output detallado (verbose)

```bash
conftest test plan.json -p ../../policy/ --verbose
```

### Paso 7 — El patrón CI/CD: apply solo si conftest pasa

```bash
# Regenerar el plan limpio (con la config correcta)
terraform plan -out=plan.tfplan
terraform show -json plan.tfplan > plan.json

# Aplicar SOLO si todas las políticas pasan
conftest test plan.json -p ../../policy/ && terraform apply plan.tfplan
```

El operador `&&` garantiza que `terraform apply` **solo se ejecuta** si `conftest` devuelve código 0. Este es el patrón exacto que se usa en pipelines CI/CD reales (GitHub Actions, Azure DevOps, GitLab CI).

---

## 💡 Integración en CI/CD (concepto)

```yaml
# .github/workflows/terraform.yml (referencia conceptual)
steps:
  - name: Terraform Plan
    run: |
      terraform plan -out=plan.tfplan
      terraform show -json plan.tfplan > plan.json

  - name: Policy Validation (OPA/conftest)
    run: conftest test plan.json -p policy/
    # Si falla: el pipeline se detiene aquí — no llega al apply

  - name: Terraform Apply
    run: terraform apply plan.tfplan
    # Solo se ejecuta si conftest retornó código 0
```

---

## 🔍 Conceptos practicados

| Concepto | Descripción |
|----------|-------------|
| **OPA (Open Policy Agent)** | Motor de políticas de propósito general, lenguaje Rego |
| **conftest** | CLI que ejecuta políticas OPA contra archivos de configuración |
| **`deny` rule** | Colección de mensajes — si tiene elementos, la política falla |
| **`plan.json`** | Representación JSON del plan Terraform, insumo para OPA |
| **Shift-left** | Detectar violaciones antes del despliegue, no después |
| **`&&` en pipeline** | Encadenamiento condicional: apply solo si conftest pasa |

---

## ✅ ¡Laboratorio completado!

Has construido el flujo completo:

1. **Módulos reutilizables** en Azure (Log Analytics + Storage + Container Apps)
2. **Composición de módulos** donde los outputs de uno alimentan los inputs de otro
3. **Policy as Code** con OPA/Rego integrado en el flujo plan → validate → apply

---

## 🧹 Limpieza

```bash
cd environments/dev/
terraform destroy -auto-approve
echo "✅ Infraestructura eliminada"
```
