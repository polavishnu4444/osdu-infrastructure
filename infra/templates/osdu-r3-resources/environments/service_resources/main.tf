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
# Private Variables  (common.tf)
#-------------------------------
locals {
  // sanitize names
  prefix = replace(trimspace(lower(var.prefix)), "_", "-")
  workspace  = replace(trimspace(lower(terraform.workspace)), "-", "")
  suffix     = var.randomization_level > 0 ? "-${random_string.workspace_scope.result}" : ""

  // base prefix for resources, prefix constraints documented here: https://docs.microsoft.com/en-us/azure/architecture/best-practices/naming-conventions
  base_name    = length(local.prefix) > 0 ? "${local.prefix}-${local.workspace}${local.suffix}" : "${local.workspace}${local.suffix}"
  base_name_21 = length(local.base_name) < 22 ? local.base_name : "${substr(local.base_name, 0, 21 - length(local.suffix))}${local.suffix}"
  base_name_46 = length(local.base_name) < 47 ? local.base_name : "${substr(local.base_name, 0, 46 - length(local.suffix))}${local.suffix}"
  base_name_60 = length(local.base_name) < 61 ? local.base_name : "${substr(local.base_name, 0, 60 - length(local.suffix))}${local.suffix}"
  base_name_76 = length(local.base_name) < 77 ? local.base_name : "${substr(local.base_name, 0, 76 - length(local.suffix))}${local.suffix}"
  base_name_83 = length(local.base_name) < 84 ? local.base_name : "${substr(local.base_name, 0, 83 - length(local.suffix))}${local.suffix}"

  tenant_id               = data.azurerm_client_config.current.tenant_id
  resource_group_name     = format("%s-%s-%s-rg", var.prefix, local.workspace, random_string.workspace_scope.result)

  // keyvault.tf
  kv_name                = "${local.base_name_21}-kv"
  ssl_cert_name          = "appgw-ssl-cert"

  // network.tf
  vnet_name              = "${local.base_name_60}-vnet"
  fe_subnet_name         = "${local.base_name_21}-fe-subnet"
  aks_subnet_name        = "${local.base_name_21}-aks-subnet"
  be_subnet_name         = "${local.base_name_21}-be-subnet"
  app_gw_name            = "${local.base_name_60}-gw"

  # aks_cluster_name       = "${local.base_name_21}-aks"
  # aks_dns_prefix         = local.base_name_60

  # aks_rg_name            = "${local.base_name_21}-aks-rg"
  # app_gw_identity_name   = "${local.base_name_21}-app-gw-identity"
   
  # app_gw_name            = "${local.base_name_60}-appgw"
  
  # agic_identity_name     = "${local.aks_cluster_name}-agic-identity"
  # pod_identity_name      = "${local.aks_cluster_name}-pod-identity"
  # sdmspod_identity_name  = "${local.aks_cluster_name}-sdmspod-identity"

  # ad_app_management_name = "${local.base_name}-ad-app-management"
  # ad_app_name            = "${local.base_name}-ad-app"            // service principal
  # graph_id               = "00000003-0000-0000-c000-000000000000" // ID for Microsoft Graph API
  # graph_role_id          = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" // ID for User.Read API
  # helm_pod_identity_ns   = "podidentity"
  # helm_agic_ns           = "agic"
  # helm_agic_name         = "agic"
  # helm_pod_identity_name = "aad-pod-identity"
}


#-------------------------------
# Common Resources  (common.tf)
#-------------------------------

data "azurerm_client_config" "current" {}

data "terraform_remote_state" "data_resources" {
  backend = "azurerm"

  config = {
    storage_account_name = var.remote_state_account
    container_name       = var.remote_state_container
    key                  = format("terraform.tfstateenv:%s", var.data_resources_workspace_name)
  }
}

data "terraform_remote_state" "common_resources" {
  backend = "azurerm"

  config = {
    storage_account_name = var.remote_state_account
    container_name       = var.remote_state_container
    key                  = format("terraform.tfstateenv:%s", var.common_resources_workspace_name)
  }
}

resource "random_string" "workspace_scope" {
  keepers = {
    # Generate a new id each time we switch to a new workspace or app id
    ws_name    = replace(trimspace(lower(terraform.workspace)), "_", "-")
    cluster_id = replace(trimspace(lower(var.prefix)), "_", "-")
  }

  length  = max(1, var.randomization_level) // error for zero-length
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

