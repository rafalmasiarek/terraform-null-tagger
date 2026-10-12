# terraform-null-tagger

Generates a standardized `name_prefix` and tag map. No real resources, no
dependency on `cloudposse/label/null`.

## Design

- `name_prefix` only, never a final name - caller relies on the target
  resource's own `name_prefix`/`bucket_prefix` for the AWS-generated suffix.
- `Name` tag is never prefixed; every other tag key gets `tag_prefix`.
- `origin_source`/`origin_version` are passive inputs - feed them from
  `data.tagger_origin.self.{source,version}`
  ([terraform-provider-tagger](https://github.com/rafalmasiarek/terraform-provider-tagger)).
- `context` carries shared settings (namespace, owner, origin, ...) from one
  base call into every other call - set once, reuse via `context =
  module.base.context`. An explicit variable on a call always wins over
  `context`.
- Predefined service tag sets: `database`, `compute`, `cache`,
  `load_balancer`, `object_storage`, `block_storage`, `kubernetes`,
  `serverless`. Flattened into `<service>-<field>` tag keys.

## Usage

```hcl
module "tagger" {
  source = "git::https://github.com/rafalmasiarek/terraform-null-tagger.git?ref=v0.1.0"

  namespace   = "acme"
  environment = "prod"
  owner       = "sre-team"

  origin_source  = data.tagger_origin.self.source
  origin_version = data.tagger_origin.self.version
}

module "tagger_sre_reports" {
  source  = "git::https://github.com/rafalmasiarek/terraform-null-tagger.git?ref=v0.1.0"
  context = module.tagger.context
  name    = "sre-reports"
}
```
