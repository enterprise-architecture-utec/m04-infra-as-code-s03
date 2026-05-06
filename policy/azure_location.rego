# policy/azure_location.rego
#
# Política: los recursos solo pueden desplegarse en regiones aprobadas.
# Objetivo: cumplimiento de residencia de datos y control de costos.
#
# Regiones permitidas: eastus, eastus2, westus2
#
# Ejecutar: conftest test plan.json -p policy/azure_location.rego

package main

import rego.v1

allowed_locations := {"eastus", "eastus2", "westus2"}

# Tipos que no tienen location directa (heredan del Resource Group)
excluded_types := {
  "azurerm_storage_container",
}

resources_with_location := [r |
  r := input.resource_changes[_]
  r.change.actions[_] in {"create", "update"}
  not excluded_types[r.type]
  r.change.after.location != null
]

# deny: región no permitida
deny contains msg if {
  resource := resources_with_location[_]
  location := resource.change.after.location
  not allowed_locations[location]
  msg := sprintf(
    "❌ [location] '%s' (%s) usa la región '%s'. Regiones permitidas: %v",
    [resource.address, resource.type, location, allowed_locations]
  )
}
