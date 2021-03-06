provider "azurerm" {
  features {}
}

module "resource_group" {
  source = "../../resource-group"

  name     = "osdu-module"
  location = "eastus2"
}

module "storage_account" {
  source = "../"

  resource_group_name = module.resource_group.name
  name                = substr("osdumodule${module.resource_group.random}", 0, 23)
  container_names = [
    "iac-container"
  ]

  resource_tags = {
    environment = "test-environment"
  }
}