# policy/azure_container_resources.rego
#
# Política: limitar los recursos asignados a contenedores en Azure Container Apps.
# Objetivo: evitar over-provisioning en el entorno compartido de clase.
#
# Límites aplicados:
#   - CPU    <= 1.0 vCPU por contenedor
#   - Memoria <= "2Gi" por contenedor
#   - Réplicas máximas <= 5
#
# Ejecutar: conftest test plan.json -p policy/azure_container_resources.rego

package main

import rego.v1

# Helpers para parsear memoria (e.g. "0.5Gi" → 0.5)
parse_memory_gi(mem_str) := value if {
  endswith(mem_str, "Gi")
  trimmed := trim_suffix(mem_str, "Gi")
  value := to_number(trimmed)
}

max_cpu    := 1.0
max_mem_gi := 2.0
max_replicas := 5

container_apps := [r |
  r := input.resource_changes[_]
  r.type == "azurerm_container_app"
  r.change.actions[_] in {"create", "update"}
]

# Obtener todos los contenedores definidos en cada Container App
all_containers := [{"app": app.address, "container": container} |
  app := container_apps[_]
  template := app.change.after.template[_]
  container := template.container[_]
]

# deny: CPU excede el límite
deny contains msg if {
  item := all_containers[_]
  cpu := to_number(item.container.cpu)
  cpu > max_cpu
  msg := sprintf(
    "❌ [container_resources] Contenedor '%s' en '%s' solicita %.2f vCPU. El máximo permitido es %.1f vCPU.",
    [item.container.name, item.app, cpu, max_cpu]
  )
}

# deny: Memoria excede el límite
deny contains msg if {
  item := all_containers[_]
  mem_val := parse_memory_gi(item.container.memory)
  mem_val > max_mem_gi
  msg := sprintf(
    "❌ [container_resources] Contenedor '%s' en '%s' solicita %sGi de memoria. El máximo permitido es %.1fGi.",
    [item.container.name, item.app, item.container.memory, max_mem_gi]
  )
}

# deny: max_replicas excede el límite
deny contains msg if {
  app := container_apps[_]
  template := app.change.after.template[_]
  replicas := template.max_replicas
  replicas > max_replicas
  msg := sprintf(
    "❌ [container_resources] '%s' tiene max_replicas = %d. El máximo permitido en el entorno de clase es %d.",
    [app.address, replicas, max_replicas]
  )
}
