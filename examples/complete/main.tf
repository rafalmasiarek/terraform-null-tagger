# One "base" call defines everything shared across the whole stack.
module "tagger" {
  source = "../../"

  namespace     = "acme"
  environment   = "prod"
  tag_prefix    = "acme:"
  owner         = "sre-team"
  owner_contact = "@sre-team"

  # In a real caller these two come from data.tagger_origin.self.{source,version}
  # (terraform-provider-tagger), not hardcoded.
  origin_source  = "github.com/rafalmasiarek/terraform-aws-vpc"
  origin_version = "v0.3.1"
}

# Every per-resource call only needs context + name - nothing else repeated.
module "tagger_sre_reports" {
  source  = "../../"
  context = module.tagger.context
  name    = "sre-reports"
}

module "tagger_other_thing" {
  source  = "../../"
  context = module.tagger.context
  name    = "other-thing"
}

output "name_prefix" {
  value = module.tagger_sre_reports.name_prefix
}

output "computed_name" {
  value = module.tagger_sre_reports.computed_name
}

output "tags_sre_reports" {
  value = module.tagger_sre_reports.tags
}

output "tags_other_thing" {
  value = module.tagger_other_thing.tags
}
