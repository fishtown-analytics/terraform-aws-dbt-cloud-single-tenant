provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

resource "helm_release" "kube_cleanup_operator" {
  count = var.enable_kube_cleanup_operator ? 1 : 0

  name       = "kube-cleanup-operator"
  repository = "https://charts.lwolf.org"
  chart      = "kube-cleanup-operator"
  version    = "1.0.1"

  namespace = var.existing_namespace ? var.custom_namespace : kubernetes_namespace.dbt_cloud.0.metadata.0.name

  values = [
    <<-EOT
    resources:
      limits:
        cpu: 250m
        memory: 500Mi
      requests:
        cpu: 250m
        memory: 250Mi

    args:
      - --namespace=${var.existing_namespace ? var.custom_namespace : kubernetes_namespace.dbt_cloud.0.metadata.0.name}
      - --dry-run=false
      - --delete-successful-after=1h
      - --delete-failed-after=1h
      - --delete-pending-pods-after=24h
      - --ignore-owned-by-cronjobs=true
      - --legacy-mode=false

    metrics:
      enabled: false
    EOT
  ]
}

resource "helm_release" "reloader" {
  count = var.enable_reloader ? 1 : 0

  name       = "reloader"
  repository = "https://stakater.github.io/stakater-charts"
  chart      = "reloader"
  version    = "0.0.75"

  namespace = var.existing_namespace ? var.custom_namespace : kubernetes_namespace.dbt_cloud.0.metadata.0.name

  set {
    name  = "reloader.logFormat"
    value = "json"
  }
}
