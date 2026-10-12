locals {
  # name_prefix: namespace/environment/attributes only - never the specific
  # resource name. The caller appends its own bare name and relies on the
  # target resource's native name_prefix/bucket_prefix/identifier_prefix
  # argument for the AWS-generated uniqueness suffix.
  name_segments_map = {
    namespace   = var.namespace
    environment = var.environment
    attributes  = join(var.delimiter, var.attributes)
  }

  name_segments_ordered = [
    for key in var.name_order : local.name_segments_map[key]
    if local.name_segments_map[key] != ""
  ]

  name_prefix = "${lower(join(var.delimiter, local.name_segments_ordered))}${var.delimiter}"

  # Only meaningful when var.name is given - the predicted full name (prefix
  # + bare name), without any AWS-generated suffix, used purely for the
  # human-readable Name tag.
  computed_name = var.name != null ? "${local.name_prefix}${var.name}" : null

  standard_tags = merge(
    {
      namespace   = var.namespace
      environment = var.environment
      owner       = var.owner
    },
    var.managed_by ? { managed-by = "terraform" } : {},
    var.owner_contact != null ? { owner-contact = var.owner_contact } : {},
    var.cost_center != null ? { cost-center = var.cost_center } : {},
    var.application != null ? { application = var.application } : {},
    var.created_at != null ? { created-at = var.created_at } : {},
    var.name != null ? { origin-name = var.name } : {},
  )

  origin_tags = var.detect_origin ? {
    origin  = try(data.external.module_origin[0].result.source, "unknown")
    version = try(data.external.module_origin[0].result.version, "unknown")
  } : {}

  prefixed_tags = {
    for k, v in merge(local.standard_tags, local.origin_tags, var.extra_tags) :
    "${var.tag_prefix}${k}" => v
  }

  # Name is special-cased: AWS Console reads this exact key, verbatim, for
  # the resource's display name - it must never carry tag_prefix.
  tags = var.name != null ? merge(local.prefixed_tags, { Name = local.computed_name }) : local.prefixed_tags
}
