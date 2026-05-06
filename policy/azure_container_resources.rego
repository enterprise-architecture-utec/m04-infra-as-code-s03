# policy/azure_container_resources.rego
#
# Política: limitar los recursos asignados a contenedores en Azure Container Apps.
# Objetivo: evitar over-provisioning en el entorno compartido de clase.
#
# Límites:
#   - CPU       <= 1.0 vCPU por contenedor
#   - Memoria   <= "2Gi" por contenedor  (formato: "0.5Gi", "1Gi", "2Gi")
#   - max_replicas <= 5
#
# Ejecutar: conftest test plan.json -p policy/azure_container_resources.rego

package main

import rego.v1

max_cpu      := 1.0
max_mem_gi   := 2.0
max_replicas := 5

# Helper: parsear "0.5Gi" → 0.5
parse_gi(mem_str) := val if {
  endswith(mem_str, "Gi")
  val := to_number(trim_suffix(mem_str, "Gi"))
}

# Todos los Container Apps que se van a crear o actualizar
container_apps := [r |
  r := input.resource_changes[_]
  r.type == "azurerm_container_app"
  r.change.actions[_] in {"create", "update"}
]

# deny: CPU excede el límite
deny contains msg if {
  app       := container_apps[_]
  template  := app.change.after.template[_]
  container := template.container[_]
  cpu       := to_number(container.cpu)
  cpu > max_cpu
  msg := sprintf(
    "❌ [container_resources] Contenedor '%s' en '%s' solicita %.2f vCPU. Máximo permitido: %.1f vCPU.",
    [container.name, app.address, cpu, max_cpu]
  )
}

# deny: Memoria excede el límite
deny contains msg if {
  app       := container_apps[_]
  template  := app.change.after.template[_]
  container := template.container[_]
  mem_val   := parse_gi(container.memory)
  mem_val > max_mem_gi
  msg := sprintf(
    "❌ [container_resources] Contenedor '%s' en '%s' solicita %s de memoria. Máximo permitido: %.1fGi.",
    [container.name, app.address, container.memory, max_mem_gi]
  )
}

# deny: max_replicas excede el límite
deny contains msg if {
  app      := container_apps[_]
  template := app.change.after.template[_]
  replicas := template.max_replicas
  replicas > max_replicas
  msg := sprintf(
    "❌ [container_resources] '%s' tiene max_replicas = %d. Máximo permitido en el entorno de clase: %d.",
    [app.address, replicas, max_replicas]
  )
}
