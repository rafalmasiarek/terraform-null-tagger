<p>
  <img
    src="https://masiarek.pl/assets/img/tagger_static/tagger-h-design-4ed344d392a25b94cde7fd92d1f691c0-400.webp"
    srcset="https://masiarek.pl/assets/img/tagger_static/tagger-h-design-4ed344d392a25b94cde7fd92d1f691c0-400.webp 400w, https://masiarek.pl/assets/img/tagger_static/tagger-h-design-4ed344d392a25b94cde7fd92d1f691c0-800.webp 800w, https://masiarek.pl/assets/img/tagger_static/tagger-h-design-4ed344d392a25b94cde7fd92d1f691c0-1200.webp 1200w, https://masiarek.pl/assets/img/tagger_static/tagger-h-design-4ed344d392a25b94cde7fd92d1f691c0-2000.webp 2000w"
    alt="Design"
    width="400"
  />
</p>

- `name_prefix` only, never a final name - caller relies on the target
  resource's own `name_prefix`/`bucket_prefix` for the AWS-generated suffix.
- `Name` and `managed-by` are never prefixed; every other tag key gets
  `tag_prefix`. `managed-by`'s key is itself overridable via
  `managed_by_key` (e.g. `"ManagedBy"`) - different tools/orgs expect
  different casing for this one.
- `origin_source`/`origin_version`/`origin_module` are passive inputs - feed
  them from `data.tagger_origin.self.{source,version}` and hardcode the module
  path (e.g. `"github.com/rafalmasiarek/terraform-aws-vpc"`). They are
  deliberately NOT inherited from `context` — each sub-module identifies
  itself independently. See [terraform-provider-tagger](https://github.com/rafalmasiarek/terraform-provider-tagger).
- `context` carries shared settings (namespace, owner, origin, ...) from one
  base call into every other call - set once, reuse via `context =
  module.base.context`. An explicit variable on a call always wins over
  `context`.
- Predefined service tag sets: `database`, `compute`, `cache`,
  `load_balancer`, `object_storage`, `block_storage`, `kubernetes`,
  `serverless`, `autoscaling_group`, `network`, `container`. Flattened
  into `<service>-<field>` tag keys.

<p>
  <img
    src="https://masiarek.pl/assets/img/tagger_static/tagger-h-usage-39fd292b354a7836f83be4024d8f17ae-400.webp"
    srcset="https://masiarek.pl/assets/img/tagger_static/tagger-h-usage-39fd292b354a7836f83be4024d8f17ae-400.webp 400w, https://masiarek.pl/assets/img/tagger_static/tagger-h-usage-39fd292b354a7836f83be4024d8f17ae-800.webp 800w, https://masiarek.pl/assets/img/tagger_static/tagger-h-usage-39fd292b354a7836f83be4024d8f17ae-1200.webp 1200w, https://masiarek.pl/assets/img/tagger_static/tagger-h-usage-39fd292b354a7836f83be4024d8f17ae-2000.webp 2000w"
    alt="Usage"
    width="400"
  />
</p>

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

### Creation timestamp

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

### Container platforms

For ECS/EKS-style stacks, share one base `context` across the stack and give
each layer - cluster, service, ASG, task EBS volume, log group - its own
per-resource call, so the whole stack carries the same convention:

| convention key | input |
|---|---|
| cluster | `service.container.cluster` |
| service | `application` |
| task family | `service.container.task_family` |
| node group | `service.container.node_group` |
| owner / environment / cost center | `owner` / `environment` / `cost_center` |

```hcl
module "tagger_api" {
  source  = "rafalmasiarek/tagger/null"
  version = ">= 0.1.0"
  context = module.tagger.context
  name    = "api"
  application = "billing"
  service = {
    container = {
      cluster     = "prod-eks"
      task_family = "api"
      node_group  = "ng-general"
    }
  }
}
```

### Computed tags (provider data sources)

Tags sourced from provider data sources (e.g. `tagger_aws_subnet`, `tagger_aws_vpc`)
become available only after the resource exists. On the first plan post-create they
appear as additions — this is expected, not drift:

```
~ tags = {
    + "network:egress-type" = "nat-gateway"
  }
```

After that apply the state is stable and no further diffs appear. In CI/CD a second
`terraform apply` (idempotent) picks them up automatically.

### Full example

```hcl
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

  service = {
    database = {
      engine         = "postgres"
      engine_version = "15.4"
      multi_az       = true
    }
  }
}

module "tagger_other_thing" {
  source  = "../../"
  context = module.tagger.context
  name    = "other-thing"
}

# Container-platform convention: shared context + per-resource call.
module "tagger_api" {
  source      = "../../"
  context     = module.tagger.context
  name        = "api"
  application = "billing"
  service = {
    container = {
      cluster     = "prod-eks"
      task_family = "api"
      node_group  = "ng-general"
    }
  }
  extra_tags = {
    tier = "frontend"
    note = "" # dropped - null/empty values never reach the tags output
  }
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

output "tags_api" {
  value = module.tagger_api.tags
}
```
