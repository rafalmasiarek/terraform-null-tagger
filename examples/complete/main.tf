# One module call for the whole stack.
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

  names = {
    sre_reports = "sre-reports"
    other_thing = "other-thing"
  }
}

# Real usage (no aws provider configured in this example, so shown as
# comments rather than actual resources):
#
# resource "aws_s3_bucket" "sre_reports" {
#   bucket_prefix = "${module.tagger.name_prefix}sre-reports-"
#   tags          = module.tagger.tags_by_name["sre_reports"]
# }
#
# resource "aws_iam_role" "other_thing" {
#   name_prefix = "${module.tagger.name_prefix}other-thing-"
#   tags        = module.tagger.tags_by_name["other_thing"]
# }

output "name_prefix" {
  value = module.tagger.name_prefix
}

output "tags_by_name" {
  value = module.tagger.tags_by_name
}
