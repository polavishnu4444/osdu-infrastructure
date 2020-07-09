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

locals {
  secrets_map = {
    # AAD Application Secrets
    # aad-client-id = module.ad_application.id

    # App Insights Secrets
    # appinsights-key = module.app_insights.app_insights_instrumentation_key

    # Service Bus Namespace Secrets
    # sb-connection = module.service_bus.service_bus_namespace_default_connection_string

    # Elastic Search Cluster Secrets
    # elastic-endpoint = var.elasticsearch_endpoint
    # elastic-username = var.elasticsearch_username
    # elastic-password = var.elasticsearch_password

    # Cosmos Cluster Secrets
    cosmos-endpoint    = data.terraform_remote_state.data_resources.outputs.cosmosdb_properties.cosmosdb.endpoint
    cosmos-primary-key = data.terraform_remote_state.data_resources.outputs.cosmosdb_properties.cosmosdb.primary_master_key
    cosmos-connection  = data.terraform_remote_state.data_resources.outputs.cosmosdb_properties.cosmosdb.connection_strings[0]

    # Storage Account Secrets
    storage-account-key = data.terraform_remote_state.data_resources.outputs.storage_properties.primary_access_key

    # Service Principal Secrets
    # app-dev-sp-username  = module.app_management_service_principal.client_id
    # app-dev-sp-password  = module.app_management_service_principal.client_secret
    # app-dev-sp-tenant-id = data.azurerm_client_config.current.tenant_id

    # App Gateway AAD Pod Identity Secrets
    # aks-app-gw-msi-client-id   = module.aks-gitops.kubelet_client_id
    # aks-app-gw-msi-resource-id = module.aks-gitops.kubelet_resource_id

  }

  output_secret_map = {
    for secret in module.keyvault_secrets.keyvault_secret_attributes :
    secret.name => secret.id
  }
}


#-------------------------------
# Key Vault
#-------------------------------
module "keyvault" {
  source              = "../../../../modules/providers/azure/keyvault"
  keyvault_name       = local.kv_name
  resource_group_name = local.resource_group_name
}

resource "azurerm_key_vault_certificate" "import" {
  count = var.ssl_certificate_file == "" ? 0 : 1

  name         = local.ssl_cert_name
  key_vault_id = module.keyvault.keyvault_id

  certificate {
    contents = filebase64(var.ssl_certificate_file)
  }

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 4096
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = "application/x-pkcs12" #application/x-pkcs12 for PFX or application/x-pem-file for PEM
    }
  }
}

# If no cert is provided then install a default one.
resource "azurerm_key_vault_certificate" "default" {
  count = var.ssl_certificate_file == "" ? 1 : 0

  name         = local.ssl_cert_name
  key_vault_id = module.keyvault.keyvault_id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = [var.dns_name, "${local.base_name}-gw.${var.resource_group_location}.cloudapp.azure.com"]
      }

      subject            = "CN=*.contoso.com"
      validity_in_months = 12
    }
  }
}

module "keyvault_secrets" {
  source      = "../../../../modules/providers/azure/keyvault-secret"
  keyvault_id = module.keyvault.keyvault_id
  secrets     = local.secrets_map
}