# terraform-null-tagger




![terraform-null-tagger](https://masiarek.pl/assets/img/tagger_static/tagger-c431ed2461f542585c65a57e0c03ba12-1200.webp)




**Standardized naming and tagging for Terraform resources.**

Computes a `name_prefix` and tag map from namespace, environment, owner,
module origin, and predefined per-service tag sets. Pure logic, no
resources of its own.






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


<p>
  <img
    src="https://masiarek.pl/assets/img/tagger_static/tagger-h-docs-8020f2ee40f61e79343e39b5c74741b5-400.webp"
    srcset="https://masiarek.pl/assets/img/tagger_static/tagger-h-docs-8020f2ee40f61e79343e39b5c74741b5-400.webp 400w, https://masiarek.pl/assets/img/tagger_static/tagger-h-docs-8020f2ee40f61e79343e39b5c74741b5-800.webp 800w, https://masiarek.pl/assets/img/tagger_static/tagger-h-docs-8020f2ee40f61e79343e39b5c74741b5-1200.webp 1200w, https://masiarek.pl/assets/img/tagger_static/tagger-h-docs-8020f2ee40f61e79343e39b5c74741b5-1983.webp 1983w"
    alt="Terraform Reference"
    width="400"
  />
</p>



### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |

### Modules

No modules.

### Resources

No resources.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | n/a | `string` | `null` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | Extra name\_prefix segments, in order (e.g. a region abbreviation like "euc1"). | `list(string)` | `null` | no |
| <a name="input_context"></a> [context](#input\_context) | Bundle of shared settings from a previous call's `context` output. Lets you set namespace/environment/owner/tag\_prefix/origin\_source/origin\_version once in a "base" call, then reuse them across many per-resource calls that only need to pass `context` + `name`. Any variable set explicitly below always overrides the matching value in `context`. | `any` | `null` | no |
| <a name="input_cost_center"></a> [cost\_center](#input\_cost\_center) | n/a | `string` | `null` | no |
| <a name="input_created_at"></a> [created\_at](#input\_created\_at) | RFC3339 timestamp, typically time\_static.created.rfc3339 in the caller - set once, never changes, to avoid perpetual plan diffs. Always specific to this one call, never taken from context. | `string` | `null` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | n/a | `string` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | e.g. dev, staging, prod. Required, either here or via context. | `string` | `null` | no |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | Custom tags, keyed however you like. A scalar value (string, bool,<br/>number) is used as-is: { security = true } -> security = "true".<br/>A map value is flattened one level deep, joined with<br/>tag\_key\_delimiter: { contact = { email = "a@b.c", phone = "123" } }<br/>-> contact<delim>email = "a@b.c", contact<delim>phone = "123".<br/>Null or empty values are dropped. | `any` | `{}` | no |
| <a name="input_managed_by"></a> [managed\_by](#input\_managed\_by) | Whether to add the managed-by=terraform tag. Falls back to context, then to true. | `bool` | `null` | no |
| <a name="input_managed_by_key"></a> [managed\_by\_key](#input\_managed\_by\_key) | Tag key for the managed-by marker - never prefixed with tag\_prefix, like Name. Falls back to context, then to "managed-by". Override if your org/tooling expects a different casing (e.g. "ManagedBy"). | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Base resource name, e.g. "sre-reports" - optional, used only for the Name/origin-name tags, and always specific to this one call (never taken from context). Never fed into name\_prefix: the module never knows the final, suffixed resource name - that's assembled by the caller via the resource's own native name\_prefix/bucket\_prefix/identifier\_prefix argument. | `string` | `null` | no |
| <a name="input_name_order"></a> [name\_order](#input\_name\_order) | Order of name\_prefix segments. Valid keys: namespace, environment, attributes. | `list(string)` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Short organization/project identifier, e.g. "acme". Required, either here or via context. | `string` | `null` | no |
| <a name="input_origin_module"></a> [origin\_module](#input\_origin\_module) | Which sub-module of the origin produced this resource, e.g. "service", "addons", "node-group". Unlike origin\_source/origin\_version this is NOT shared via context - it's specific to each sub-module and is set per call so a stack built from one origin repo can still show which sub-module created each resource. Null when the caller doesn't track sub-modules (single-module origins). | `string` | `null` | no |
| <a name="input_origin_source"></a> [origin\_source](#input\_origin\_source) | Where the calling module came from, e.g. "github.com/rafalmasiarek/terraform-aws-vpc". Passive input - this module never detects it itself; pass it from data.tagger\_origin.self.source (terraform-provider-tagger) or hardcode it, usually via context so every resource in a stack shares the same value. | `string` | `null` | no |
| <a name="input_origin_version"></a> [origin\_version](#input\_origin\_version) | Version/ref of the calling module. Passive input, usually shared via context like origin\_source. | `string` | `null` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Team or person accountable for the resource. Required, either here or via context. | `string` | `null` | no |
| <a name="input_owner_contact"></a> [owner\_contact](#input\_owner\_contact) | Email or @handle (Teams/Slack), e.g. "sre-team@acme.com" or "@sre-team". | `string` | `null` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regex matching characters to strip from namespace/environment/attributes/name before use. Falls back to context, then to "/[^a-zA-Z0-9-]/" (letters, digits, hyphen only). | `string` | `null` | no |
| <a name="input_service"></a> [service](#input\_service) | Service-category tag data (database, compute, cache, load\_balancer, object\_storage, block\_storage, kubernetes, serverless, autoscaling\_group, network, container). See this file's comment above for each category's recognized fields. | `any` | `{}` | no |
| <a name="input_tag_key_delimiter"></a> [tag\_key\_delimiter](#input\_tag\_key\_delimiter) | Separator used inside composite tag key names (e.g. "cost<sep>center", "db<sep>engine"). Falls back to context, then to ":" (a tag tree, e.g. "tagger:cost:center"). Set to "-" for a flat key instead. | `string` | `null` | no |
| <a name="input_tag_prefix"></a> [tag\_prefix](#input\_tag\_prefix) | Namespace prefix for tag keys, e.g. "acme:". Falls back to context, then to "tagger:". Never applied to the "Name" tag - AWS reads that key verbatim for the console display name. | `string` | `null` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_computed_name"></a> [computed\_name](#output\_computed\_name) | name\_prefix + var.name, without any AWS-generated suffix. Null if var.name was not given. |
| <a name="output_context"></a> [context](#output\_context) | Bundle of every shared, stack-wide setting (namespace, environment, owner, tag\_prefix, origin\_source, origin\_version, ...) from this call - pass straight into a later call's `context` input to avoid repeating them per resource. |
| <a name="output_name_prefix"></a> [name\_prefix](#output\_name\_prefix) | namespace-environment-attributes-, ready to concatenate with the caller's own resource name. |
| <a name="output_tags"></a> [tags](#output\_tags) | Full tag map, including Name (unprefixed) and every other tag key under tag\_prefix. |

### Examples

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



<img
  src="https://masiarek.pl/assets/img/tagger_static/tagger-h-license-5e8a6f433e1d68e761f8f6dbb3dc4dcf-400.webp"
  srcset="https://masiarek.pl/assets/img/tagger_static/tagger-h-license-5e8a6f433e1d68e761f8f6dbb3dc4dcf-400.webp 400w, https://masiarek.pl/assets/img/tagger_static/tagger-h-license-5e8a6f433e1d68e761f8f6dbb3dc4dcf-800.webp 800w, https://masiarek.pl/assets/img/tagger_static/tagger-h-license-5e8a6f433e1d68e761f8f6dbb3dc4dcf-1200.webp 1200w, https://masiarek.pl/assets/img/tagger_static/tagger-h-license-5e8a6f433e1d68e761f8f6dbb3dc4dcf-2000.webp 2000w"
  width="400"
  alt="License"
/>


[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

```text
The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files, to deal in the Software
without restriction.

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.

Source: https://opensource.org/licenses/MIT
```


See [LICENSE](LICENSE) for full details.


<img
  src="https://masiarek.pl/assets/img/tagger_static/tagger-h-authors-3c1fe623e8489e8e4d6f644e5ddc129c-400.webp"
  srcset="https://masiarek.pl/assets/img/tagger_static/tagger-h-authors-3c1fe623e8489e8e4d6f644e5ddc129c-400.webp 400w, https://masiarek.pl/assets/img/tagger_static/tagger-h-authors-3c1fe623e8489e8e4d6f644e5ddc129c-800.webp 800w, https://masiarek.pl/assets/img/tagger_static/tagger-h-authors-3c1fe623e8489e8e4d6f644e5ddc129c-1200.webp 1200w, https://masiarek.pl/assets/img/tagger_static/tagger-h-authors-3c1fe623e8489e8e4d6f644e5ddc129c-2000.webp 2000w"
  width="400"
  alt="Authors"
/>


- Rafał Masiarek | [website](https://masiarek.pl) | [email](mailto:rafal@masiarek.pl) | [github](https://github.com/rafalmasiarek)




<p align="right">
  <img
    src="https://masiarek.pl/assets/img/tagger_static/tagger-h-author-sign-0d994b53a6ca9c892fbc63c7e9e112f0-400.webp"
    srcset="https://masiarek.pl/assets/img/tagger_static/tagger-h-author-sign-0d994b53a6ca9c892fbc63c7e9e112f0-400.webp 400w, https://masiarek.pl/assets/img/tagger_static/tagger-h-author-sign-0d994b53a6ca9c892fbc63c7e9e112f0-800.webp 800w, https://masiarek.pl/assets/img/tagger_static/tagger-h-author-sign-0d994b53a6ca9c892fbc63c7e9e112f0-1200.webp 1200w, https://masiarek.pl/assets/img/tagger_static/tagger-h-author-sign-0d994b53a6ca9c892fbc63c7e9e112f0-2000.webp 2000w"
    alt="by Rafał Masiarek"
    width="280"
  />
</p>



<!-- references -->

[repo_link]: https://github.com/rafalmasiarek/terraform-null-tagger
