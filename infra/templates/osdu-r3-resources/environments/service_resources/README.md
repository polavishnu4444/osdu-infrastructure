# Azure OSDU R3 - Cluster Resources Environment

The `osdu` - `cluster_resources` environment template is intended to provision to Azure resources for an AKS Cluster. 


# Deployment Steps

## Source your environment 

Execute the following commands to set up your local environment variables:

*Note for Windows Users using WSL*: We recommend running dos2unix utility on the environment file via `dos2unix .env` prior to sourcing your environment variables to chop trailing newline and carriage return characters.

```bash
# these commands setup all the environment variables needed to run this template
DOT_ENV=<path to your .env file>
export $(cat $DOT_ENV | xargs)
```

## Service Principal Login

Execute the following command to configure your local Azure CLI.

```bash
# This logs your local Azure CLI in using the configured service principal.
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
```

## Define Terraform Variables

Navigate to the `terraform.tfvars` terraform file. Here's a sample of the terraform.tfvars file for this template. Be sure to update the `gitops_ssh_url` TF var with the git url of the GitOPS repo.
![image](images/ssh_clone.png)


```HCL
resource_group_location     = "centralus"
prefix                      = "osdu-r2"
acr_resource_group_name     = "osdu-r2-acr"
acr_container_registry_name = "osducr"
data_resource_prefix        = "data-dev-int-osdur2"
gitops_ssh_url              = "git@ssh.dev.azure.com:v3/slb-des-ext-collaboration/open-data-ecosystem/k8-gitops-hld"
sb_topics = []
```

## Initialize your workspace

Execute the following commands to set up your terraform workspace.

```bash
# This configures terraform to leverage a remote backend that will help you and your
# team keep consistent state
terraform init -backend-config "storage_account_name=${TF_VAR_remote_state_account}" -backend-config "container_name=${TF_VAR_remote_state_container}"

# This command configures terraform to use a workspace unique to you. This allows you to work
# without stepping over your teammate's deployments
TF_WORKSPACE="dev-int-aks"
terraform workspace new $TF_WORKSPACE || terraform workspace select $TF_WORKSPACE
```

## Terraform Plan

Next, execute terraform plan and specify the location of our variables file. Terraform looks for `terraform.tfvars` in the current directory as a default.

```bash
# See what terraform will try to deploy without actually deploying
terraform plan
```

## Terraform Apply

The final step is to issue terraform apply which uses the file containing the variables we defined above (if you run terraform apply without -var-file= it will take any *.tfvars file in the folder, for example, the sample terraform.tfvars file, if you didn't remove it, and start asking for the unspecified fields).

```bash
# Execute a deployment
terraform apply
```

## License
Copyright © Microsoft Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at 

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.