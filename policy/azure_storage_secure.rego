# policy/azure_storage_secure.rego
#
# Política: los Storage Accounts deben cumplir estándares de seguridad.
# Valida:
#   1. allow_nested_items_to_be_public = false  (sin acceso público a blobs)
#   2. min_tls_version = "TLS1_2"               (protocolo mínimo)
#   3. https_traffic_only_enabled = true         (solo HTTPS)
#
# Ejecutar: conftest test plan.json -p policy/azure_storage_secure.rego

package main

import rego.v1

storage_accounts := [r |
  r := input.resource_changes[_]
  r.type == "azurerm_storage_account"
  r.change.actions[_] in {"create", "update"}
]

# deny: acceso público habilitado
deny contains msg if {
  sa := storage_accounts[_]
  sa.change.after.allow_nested_items_to_be_public == true
  msg := sprintf(
    "❌ [storage_secure] '%s' tiene acceso público a blobs habilitado. Establece allow_nested_items_to_be_public = false.",
    [sa.address]
  )
}

# deny: TLS menor a 1.2
deny contains msg if {
  sa := storage_accounts[_]
  tls := object.get(sa.change.after, "min_tls_version", "TLS1_0")
  tls != "TLS1_2"
  msg := sprintf(
    "❌ [storage_secure] '%s' usa TLS versión '%s'. Se requiere min_tls_version = 'TLS1_2'.",
    [sa.address, tls]
  )
}

# deny: tráfico HTTP permitido
deny contains msg if {
  sa := storage_accounts[_]
  object.get(sa.change.after, "https_traffic_only_enabled", false) == false
  msg := sprintf(
    "❌ [storage_secure] '%s' permite tráfico HTTP. Establece https_traffic_only_enabled = true.",
    [sa.address]
  )
}
