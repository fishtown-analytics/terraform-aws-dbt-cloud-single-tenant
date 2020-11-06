# required variables
variable "namespace" {
  type        = string
  description = "Used as an identifier for various infrastructure components within the module. Usually single word that or the name of the organization. For exmaple: 'fishtownanalytics'"
}
variable "environment" {
  type        = string
  description = "The name of the environment for the deployment. For example: 'dev', 'prod', 'uat', 'standard', 'etc'"
}
variable "k8s_node_count" {
  type        = number
  description = "The number of Kubernetes nodes that will be created for the EKS worker group. Generally 2 nodes are recommended but it is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to setting this."
}
variable "k8s_node_size" {
  type        = string
  description = "The EC2 instance type of the Kubernetes nodes that will be created for the EKS worker group. It is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to setting this."
}
variable "region" {
  type        = string
  description = "The AWS region where the infrastructure will be deployed. For example 'us-east-1'."
}
variable "postgres_instance_class" {
  type        = string
  description = "The RDS Postgres instance type. It is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to setting this."
}
variable "postgres_storage" {
  type        = string
  description = "The amount of storage allocated to the RDS database in GB. Generally 100 GB is standard but it is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to setting this."
}
variable "cidr_block" {
  type        = string
  description = "The CIDR block of the VPC that the infrastructure will be deployed in."
}
variable "key_admins" {
  type        = list(string)
  description = "Required list of admin users for KMS key creation. This list should include at least one valid admin user for the AWS account."
}
variable "rds_password" {
  type        = string
  description = "Password for RDS database. It is highly recommended that a secure password be generated and stored in a vault."
}
variable "vpc_id" {
  type        = string
  description = "The ID of the VPC that the infrastructure will be deployed in."
}
variable "private_subnets" {
  type        = list(string)
  description = "The list of private subnets for the VPC that the infrastructure will be deployed in."
}
variable "hosted_zone_name" {
  type        = string
  description = "The root domain name of the hosted zone that will resolve to the dbt Cloud deployment. This should be a valid domain name that you own."
}

# optional variables
variable "key_users" {
  type        = list(string)
  default     = []
  description = "List of key users for the KMS key creation. This can be left as an empty list unless adding users to KMS key is desired."
}
variable "enable_ses" {
  type        = bool
  default     = false
  description = "If set to 'true' this will attempt to create an key pair for AWS Simple Email Service. If set to 'true' a valid from email address must be set in the 'ses_email' variable."
}
variable "ses_email" {
  type        = string
  default     = ""
  description = "A valid from email address to be used for AWS SES. This address will receive a validation email from AWS upon apply."
}
variable "ses_header" {
  type        = string
  default     = ""
  description = "The email header for notifications sent via SES. If left blank the header will simply display as the address set in the 'ses_email' variable."
}
variable "load_balancer_source_ranges" {
  type        = list(string)
  default     = []
  description = "A list of IP ranges in CIDR notation that will be whitelisted by the loadbalancer. If unset will default to allow all traffic."
}
variable "create_admin_console_script" {
  type        = bool
  default     = false
  description = "If set to true will generate a script to automatically spin up the KOTS admin console with desired values and outputs from the module. The relevant variables below are suffixed with '(Optional) Admin Console Script' in their descriptions. These variables can also be left blank and manually entered into the script after applying if desired."
}
variable "aws_access_key_id" {
  type        = string
  default     = "<ENTER_AWS_ACCESS_KEY>"
  description = "(Optional) Admin Console Script - The AWS access key for an IAM identity with admin access that will be used for encryption. This is added to the config that is automatically uploaded to the KOTS admin console via the script."
}
variable "aws_secret_access_key" {
  type        = string
  default     = "<ENTER_AWS_SECRET_KEY>"
  description = "(Optional) Admin Console Script - The AWS secret key for an IAM identity with admin access that will be used for encryption. This is added to the config that is automatically uploaded to the KOTS admin console via the script."
}
variable "creation_role_arn" {
  type        = string
  default     = "<ENTER_CREATION_ROLE_ARN>"
  description = "(Optional) Admin Console Script - The ARN of the Terraform Creation Role. This is added to the script and used when setting the K8s context."
}
variable "admin_console_password" {
  type        = string
  default     = "<ENTER_ADMIN_CONSOLE_PASSWORD>"
  description = "(Optional) Admin Console Script - The desired password for the KOTS admin console. This is added to the script and used when spinning the admin console."
}
variable "superuser_password" {
  type        = string
  default     = "<ENTER_SUPER_USER_PASSWORD>"
  description = "(Optional) Admin Console Script - The superuser password for the dbt Cloud application. This is added to the config that is automatically uploaded to the KOTS admin console via the script."
}
variable "datadog_enabled" {
  type        = bool
  default     = false
  description = "If set to true this will enable dbt Cloud to send metrics to Datadog. Note that this requires the installation of a Datadog Agent in the K8s cluster where dbt Cloud is deployed."
}
variable "hostname_affix" {
  type        = string
  default     = ""
  description = "The affix of the URL, affixed to the 'hosted_zone_name' variable, that the dbt Cloud deployment will resolve to. If left blank the affix will default to the value of the 'environment' variable."
}
variable "release_channel" {
  type        = string
  default     = ""
  description = "(Optional) Admin Console Script - The license channel for customer deployment. This should be left unset unless instructed by Fishtown Analytics."
}
variable "app_memory" {
  type        = string
  default     = "1Gi"
  description = "(Optional) Admin Console Script - The memory dedicated to the application pods for dbt Cloud. This is added to the config that is automatically uploaded to the KOTS admin console via the script. This value should never be set to less than default. It is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to modifying this."
}
variable "app_replicas" {
  type        = number
  default     = 2
  description = "(Optional) Admin Console Script - The number of application pods for dbt Cloud. This is added to the config that is automatically uploaded to the KOTS admin console via the script. This value should never be set to less than default. It is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to modifying this."
}
variable "nginx_memory" {
  type        = string
  default     = "500mi"
  description = "(Optional) Admin Console Script - The amount of memory dedicated to nginx for dbt Cloud. This is added to the config that is automatically uploaded to the KOTS admin console via the script. This value should never be set to less than default. It is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to modifying this."
}
variable "scheduler_memory" {
  type        = string
  default     = "1Gi"
  description = "(Optional) Admin Console Script - The amount of memory dedicated to the scheduler for dbt Cloud. This is added to the config that is automatically uploaded to the KOTS admin console via the script. This value should never be set to less than default. It is recommended that you reach out to Fishtown Analytics to complete the capacity planning exercise prior to modifying this."
}
variable "additional_k8s_user_data" {
  type        = string
  default     = ""
  description = "Any additonal user data for K8s worker nodes. For example a curl script to install auditing software."
}
variable "create_efs_provisioner" {
  type        = bool
  default     = true
  description = "Set to false if creating a custom EFS provisioner storage class for the IDE."
}
variable "ide_storage_class" {
  type        = string
  default     = "aws-efs"
  description = "(Optional) Admin Console Script - The EFS provisioner storage class name used for the IDE. Only change if creating a custom EFS provisioner."
}
variable "create_loadbalancer" {
  type        = bool
  default     = true
  description = "Set to false if creating a customer load balancer or other networking device to route traffic within the cluster."
}
variable "rds_backup_retention_period" {
  type        = number
  default     = 7
  description = "The number of days for RDS to create automated snapshot backups. Set to a max of 35 or set to 0 to disable automated backups."
}

# locals
data "aws_caller_identity" "current" {}
locals {
  account_id = data.aws_caller_identity.current.account_id
}
