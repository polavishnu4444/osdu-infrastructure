//  Copyright © Microsoft Corporation
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.


/*
.Synopsis
   Terraform Main Control
.DESCRIPTION
   This file holds the main control and resoures for bootstraping an OSDU Azure Devops Project.
*/

terraform {
  required_version = ">= 0.12"
  backend "azurerm" {
    key = "terraform.tfstate"
  }
}


#-------------------------------
# Providers
#-------------------------------
provider "azurerm" {
  version = "~> 2.8.0"
  features {}
}

provider "null" {
  version = "~>2.1.0"
}

provider "azuread" {
  version = "~>0.7.0"
}

provider "external" {
  version = "~> 1.0"
}


#-------------------------------
# Application Variables  (variables.tf)
#-------------------------------
variable "prefix" {
  description = "The workspace prefix defining the project area for this terraform deployment."
  type        = string
}

variable "resource_group_location" {
  description = "The Azure region where data storage resources in this template should be created."
  type        = string
}

variable "storage_containers" {
  description = "The list of storage container names to create. Names must be unique per storage account."
  type        = list(string)
}

variable "cosmos_db_name" {
  description = "(Required) The name that CosmosDB will be created with."
  type        = string
}

variable "cosmosdb_replica_location" {
  description = "The name of the Azure region to host replicated data. i.e. 'East US' 'East US 2'. More locations can be found at https://azure.microsoft.com/en-us/global-infrastructure/locations/"
  type        = string
}

variable "cosmosdb_consistency_level" {
  description = "The level of consistency backed by SLAs for Cosmos database. Developers can chose from five well-defined consistency levels on the consistency spectrum."
  type        = string
  default     = "Session"
}

variable "cosmosdb_automatic_failover" {
  description = "Determines if automatic failover is enabled for CosmosDB."
  type        = bool
  default     = true
}


#-------------------------------
# Private Variables  (common.tf)
#-------------------------------
locals {
  // sanitize names
  resource_prefix = replace(format("%s-%s", trimspace(lower(terraform.workspace)), random_string.main.result), "_", "-")
  workspace       = replace(trimspace(lower(terraform.workspace)), "-", "")
  resource_group_name     = format("%s-%s-%s-rg", var.prefix, local.workspace, random_string.main.result)
  storage_name    = "${replace(local.resource_prefix, "-", "")}sa" // storage account
  cosmosdb_name   = "${local.resource_prefix}-cosmosdb"            // cosmosdb account (max 44 chars )  
}


#-------------------------------
# Common Resources  (common.tf)
#-------------------------------
resource "random_string" "main" {
  keepers = {
    # Generate a new id each time we switch to a new workspace or app id
    ws_name = replace(trimspace(lower(terraform.workspace)), "-", "")
    prefix  = replace(trimspace(lower(var.prefix)), "_", "-")
  }

  length  = 4
  special = false
  upper   = false
}


#-------------------------------
# Resource Group
#-------------------------------
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_management_lock" "rg_lock" {
  name       = "osdu_ds_rg_lock"
  scope      = azurerm_resource_group.main.id
  lock_level = "CanNotDelete"
}


#-------------------------------
# Storage
#-------------------------------
module "storage_account" {
  source = "../../../../modules/providers/azure/storage-account"

  name                = local.storage_name
  resource_group_name = azurerm_resource_group.main.name
  container_names     = var.storage_containers
  kind                = "StorageV2"
}

resource "azurerm_management_lock" "sa_lock" {
  name       = "osdu_ds_sa_lock"
  scope      = module.storage_account.id
  lock_level = "CanNotDelete"
}


#-------------------------------
# CosmosDB
#-------------------------------
module "cosmosdb_account" {
  source                   = "../../../../modules/providers/azure/cosmosdb"
  name                     = local.cosmosdb_name
  resource_group_name      = azurerm_resource_group.main.name
  primary_replica_location = var.cosmosdb_replica_location
  automatic_failover       = var.cosmosdb_automatic_failover
  consistency_level        = var.cosmosdb_consistency_level
}

resource "azurerm_management_lock" "db_lock" {
  name       = "osdu_ds_db_lock"
  scope      = module.cosmosdb_account.properties.cosmosdb.id
  lock_level = "CanNotDelete"
}


#-------------------------------
# Output Variables  (output.tf)
#-------------------------------
output "resource_group_name" {
  description = "The name of the resource group containing the data specific resources"
  value       = azurerm_resource_group.main.name
}

output "storage_account" {
  description = "The name of the storage account."
  value       = module.storage_account.name
}

output "storage_account_id" {
  description = "The resource identifier of the storage account."
  value       = module.storage_account.id
}

output "storage_account_containers" {
  description = "Map of storage account containers."
  value       = module.storage_account.containers
}

output "cosmosdb_properties" {
  description = "Properties of the deployed CosmosDB account."
  value       = module.cosmosdb_account.properties
}

output "cosmosdb_account_name" {
  description = "The name of the CosmosDB account."
  value       = module.cosmosdb_account.account_name
}

