<p align="center">
  <img
    src="https://masiarek.pl/assets/img/tagger-1200-q82.webp"
    alt="terraform-null-tagger - Terraform module for standardized resource naming and tagging"
    width="600"
  />
</p>

# terraform-null-tagger

Generates a standardized `name_prefix` and tag map. No real resources, no
dependency on `cloudposse/label/null`.

## Design

- `name_prefix` only, never a final name - caller relies on the target
  resource's own `name_prefix`/`bucket_prefix` for the AWS-generated suffix.
- `Name` and `managed-by` are never prefixed; every other tag key gets
  `tag_prefix`. `managed-by`'s key is itself overridable via
  `managed_by_key` (e.g. `"ManagedBy"`) - different tools/orgs expect
  different casing for this one.
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
  source  = "rafalmasiarek/tagger/null"
  version = ">= 0.1.0"

  namespace   = "acme"
  environment = "prod"
  owner       = "sre-team"

  origin_source  = data.tagger_origin.self.source
  origin_version = data.tagger_origin.self.version
}

module "tagger_sre_reports" {
  source  = "rafalmasiarek/tagger/null"
  version = ">= 0.1.0"
  context = module.tagger.context
  name    = "sre-reports"
}
```

## Creation timestamp

`created_at` takes a plain string - this module does not create anything,
so it can't freeze a timestamp on its own. Use `time_static`, which only
computes its value once and never recomputes it on later plans/applies:

```hcl
resource "time_static" "created" {}

module "tagger_sre_reports" {
  source     = "rafalmasiarek/tagger/null"
  version    = ">= 0.1.0"
  context    = module.tagger.context
  name       = "sre-reports"
  created_at = time_static.created.rfc3339
}
```

Passing `timestamp()` directly instead of `time_static.created.rfc3339`
causes a tag change on every single apply - `timestamp()` re-evaluates
every run, `time_static` does not.

`created_at` is deliberately excluded from `context` (always specific to
the one call it's given to) - set it on the base `tagger` call and it will
*not* propagate to `tagger_sre_reports`. Pass `time_static.created.rfc3339`
explicitly on every call that needs it.
