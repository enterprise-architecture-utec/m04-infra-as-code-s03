# policy/azure_required_tags.rego
#
# Política: todos los recursos Azure deben tener los tags obligatorios.
# Tags requeridos: Environment, ManagedBy, Owner, CostCenter
#
# Objetivo: rastreabilidad, gestión de costos y gobernanza en la
# suscripción compartida de los 34 alumnos.
#
# Ejecutar: conftest test plan.json -p policy/azure_required_tags.rego

package main

import rego.v1

required_tags := {"Environment", "ManagedBy", "Owner", "CostCenter"}

# Tipos de recursos que no soportan tags directamente en Azure
excluded_types := {
  "azurerm_storage_container",
}

# Recursos que se van a crear o actualizar
taggable_resources := [r |
  r := input.resource_changes[_]
  r.change.actions[_] in {"create", "update"}
  not excluded_types[r.type]
  r.change.after != null
]

# deny: falta un tag obligatorio
deny contains msg if {
  resource := taggable_resources[_]
  tags := object.get(resource.change.after, "tags", {})
  required_tag := required_tags[_]
  not tags[required_tag]
  msg := sprintf(
    "❌ [required_tags] '%s' (%s) no tiene el tag obligatorio: '%s'",
    [resource.address, resource.type, required_tag]
  )
}

# deny: tag presente pero vacío
deny contains msg if {
  resource := taggable_resources[_]
  tags := object.get(resource.change.after, "tags", {})
  required_tag := required_tags[_]
  tags[required_tag] == ""
  msg := sprintf(
    "❌ [required_tags] '%s' tiene el tag '%s' vacío. Los tags obligatorios no pueden estar en blanco.",
    [resource.address, required_tag]
  )
}
