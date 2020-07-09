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


#-------------------------------
# Network
#-------------------------------

module "network" {
  source              = "../../../../modules/providers/azure/network"

  name                = local.vnet_name
  resource_group_name = local.resource_group_name
  address_space       = var.address_space
  dns_servers         = ["8.8.8.8"]
  subnet_prefixes     = [var.subnet_fe_prefix, var.subnet_aks_prefix, var.subnet_be_prefix]
  subnet_names        = [local.fe_subnet_name, local.aks_subnet_name, local.be_subnet_name]
}

module "appgateway" {
  source              = "../../../../modules/providers/azure/aks-appgw"

  name                 = local.app_gw_name
  resource_group_name  = local.resource_group_name
  vnet_name            = module.network.name
  vnet_subnet_id       = module.network.subnets.0
  keyvault_id          = module.keyvault.keyvault_id
  keyvault_secret_id   = azurerm_key_vault_certificate.default[0].secret_id  # TODO: If not default then import
  ssl_certificate_name = local.ssl_cert_name
}