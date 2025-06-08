locals {
  log_retention_days = var.log_retention_in_days != null ? var.log_retention_in_days : 14
  common_tags = merge(
    var.common_tags
  )
}