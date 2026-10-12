module "tagger" {
  source = "../../"

  namespace     = "acme"
  environment   = "prod"
  name          = "sre-reports"
  tag_prefix    = "acme:"
  owner         = "sre-team"
  owner_contact = "@sre-team"
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
