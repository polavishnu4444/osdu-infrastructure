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

module "aks-gitops" {
  source = "../../../../modules/providers/azure/aks-gitops"

  name                 = local.aks_cluster_name
  resource_group_name  = local.resource_group_name
  dns_prefix           = local.aks_dns_prefix
  agent_vm_count       = var.aks_agent_vm_count
  agent_vm_size        = var.aks_agent_vm_size
  vnet_subnet_id       = module.network.subnets.1
  ssh_public_key       = file(var.ssh_public_key_file)
  kubernetes_version   = var.kubernetes_version

  acr_enabled          = true
  gc_enabled           = true
  msi_enabled          = true
  oms_agent_enabled    = true
  flux_recreate        = var.flux_recreate
  
  gitops_ssh_url       = var.gitops_ssh_url
  gitops_ssh_key       = var.gitops_ssh_key_file
  gitops_url_branch    = var.gitops_config.branch
  gitops_path          = var.gitops_config.path
  gitops_poll_interval = var.gitops_config.interval
  gitops_label         = var.gitops_config.label
}