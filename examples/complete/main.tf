module "tagger" {
  source = "../../"

  namespace     = "acme"
  environment   = "prod"
  name          = "sre-reports"
  tag_prefix    = "acme:"
  owner         = "sre-team"
  owner_contact = "@sre-team"

  # In a real caller these two come from data.tagger_origin.self.{source,version}
  # (terraform-provider-tagger), not hardcoded - shown here as plain values
  # since this module never detects them itself.
  origin_source  = "github.com/rafalmasiarek/terraform-aws-vpc"
  origin_version = "v0.3.1"
}

output "name_prefix" {
  value = module.tagger.name_prefix
}

output "computed_name" {
  value = module.tagger.computed_name
}

output "tags" {
  value = module.tagger.tags
}
