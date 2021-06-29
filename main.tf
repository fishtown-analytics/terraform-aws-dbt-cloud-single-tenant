resource "aws_security_group" "internal" {
  count       = var.custom_internal_security_group_id == "" ? 1 : 0
  name        = "internal"
  description = "Allow all internal traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = [ingress]
  }

  tags = map(
    "Name", "internal",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}

module "efs" {
  source  = "cloudposse/efs/aws"
  version = "0.22.0"

  namespace   = var.namespace
  environment = var.environment
  name        = "efs-${var.namespace}-${var.environment}"

  region          = var.region
  vpc_id          = var.vpc_id
  subnets         = var.private_subnets
  security_groups = [var.custom_internal_security_group_id == "" ? aws_security_group.internal.0.id : var.custom_internal_security_group_id]
  encrypted       = true
  kms_key_id      = module.kms_key.key_arn

  tags = map(
    "Name", "efs-${var.namespace}-${var.environment}",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}

resource "aws_db_subnet_group" "private" {
  name       = "private-${var.namespace}-${var.environment}"
  subnet_ids = var.private_subnets

  tags = map(
    "Name", "private",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}

resource "aws_db_instance" "backend_postgres" {
  identifier             = "${var.namespace}-${var.environment}"
  name                   = "${var.namespace}${var.environment}"
  instance_class         = var.postgres_instance_class
  allocated_storage      = var.postgres_storage
  engine                 = "postgres"
  username               = "${var.namespace}${var.environment}"
  password               = var.rds_password
  storage_encrypted      = true
  multi_az               = var.rds_multi_az
  kms_key_id             = module.kms_key.key_arn
  db_subnet_group_name   = aws_db_subnet_group.private.name
  vpc_security_group_ids = [var.custom_internal_security_group_id == "" ? aws_security_group.internal.0.id : var.custom_internal_security_group_id]

  skip_final_snapshot = true
  deletion_protection = true

  backup_retention_period  = var.rds_backup_retention_period
  delete_automated_backups = false

  lifecycle {
    ignore_changes = [password]
  }

  tags = map(
    "Name", "backend_postgres",
    "workload-type", "other",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}

module "aurora" {
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "~> 3.0"

  name           = "${var.namespace}${var.environment}"
  engine         = "aurora-postgresql"
  engine_version = "11.9"
  instance_type  = "db.r5.large" # TODO - parameterize and figure out correct size

  vpc_id  = var.vpc_id
  subnets = var.private_subnets

  replica_count           = 1
  allowed_security_groups = [var.custom_internal_security_group_id == "" ? aws_security_group.internal.0.id : var.custom_internal_security_group_id]
  allowed_cidr_blocks     = [var.cidr_block]

  storage_encrypted   = true
  apply_immediately   = true
  monitoring_interval = 10

  db_parameter_group_name         = "default"
  db_cluster_parameter_group_name = "default"

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = map(
    "Name", "efs-${var.namespace}-${var.environment}",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}

resource "kubernetes_namespace" "dbt_cloud" {
  count = var.existing_namespace ? 0 : 1
  metadata {
    name = var.custom_namespace == "" ? "dbt-cloud-${var.namespace}-${var.environment}" : var.custom_namespace
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.9"
}

locals {
  map_roles_sso = [
    {
      rolearn  = var.rbac_sso_view_only_role_arn
      username = "IAMViewOnlyRole"
      groups   = ["viewonlyusers"]
    },
    {
      rolearn  = var.rbac_sso_power_user_role_arn
      username = "IAMPowerUserRole"
      groups   = ["powerusers"]
    },
    {
      rolearn  = var.rbac_sso_admin_role_arn
      username = "IAMAdministratorRole"
      groups   = ["system:masters"]
    },
  ]
}

module "eks" {
  count   = var.create_eks_cluster ? 1 : 0
  source  = "terraform-aws-modules/eks/aws"
  version = "13.0.0"

  create_eks = true

  cluster_version = "1.17"
  cluster_name    = "${var.namespace}-${var.environment}"
  vpc_id          = var.vpc_id
  subnets         = var.private_subnets

  worker_groups_launch_template = [
    {
      name = "primary-worker-group-1-17-${var.k8s_node_size}"

      # override ami_id for this launch template
      ami_id = local.eks_worker_ami

      instance_type        = var.k8s_node_size
      asg_desired_capacity = var.k8s_node_count
      asg_min_size         = var.k8s_node_count
      asg_max_size         = var.k8s_node_count

      suspended_processes = ["AZRebalance"]

      key_name                      = "${var.namespace}-${var.environment}"
      additional_security_group_ids = [var.custom_internal_security_group_id == "" ? aws_security_group.internal.0.id : var.custom_internal_security_group_id]
      kubelet_extra_args            = local.kubelet_extra_args_1_17
      pre_userdata                  = "${local.bionic_node_userdata}${var.additional_k8s_user_data}"

      enabled_metrics = [
        "GroupStandbyInstances",
        "GroupTotalInstances",
        "GroupPendingInstances",
        "GroupTerminatingInstances",
        "GroupDesiredCapacity",
        "GroupInServiceInstances",
        "GroupMinSize",
        "GroupMaxSize",
      ]
    },
  ]

  workers_role_name           = "${var.namespace}-${var.environment}-workers-role"
  workers_additional_policies = local.aws_worker_policy_arns

  cluster_log_retention_in_days = 0
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]

  cluster_endpoint_private_access = true

  manage_aws_auth = true
  map_roles       = var.enable_rbac_sso == true ? local.map_roles_sso : []

  write_kubeconfig = false

  tags = map(
    "Name", "eks",
    "Stack", "${var.namespace}-${var.environment}",
    "Customer", var.namespace
  )
}
