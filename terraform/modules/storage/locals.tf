locals {
  storage_contract = {
    environment         = var.environment
    storage_definitions = var.storage_definitions
  }

  storage_by_type = {
    block  = { for key, definition in var.storage_definitions : key => definition if definition.storage_type == "block" }
    shared = { for key, definition in var.storage_definitions : key => definition if definition.storage_type == "shared" }
    object = { for key, definition in var.storage_definitions : key => definition if definition.storage_type == "object" }
  }
}
