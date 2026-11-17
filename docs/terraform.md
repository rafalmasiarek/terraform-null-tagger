<p>
  <img
    src="https://masiarek.pl/assets/img/tagger_static/tagger-h-tf-references-8ae09efcc24e2598273c7f8a5e802ac8-400.webp"
    srcset="https://masiarek.pl/assets/img/tagger_static/tagger-h-tf-references-8ae09efcc24e2598273c7f8a5e802ac8-400.webp 400w, https://masiarek.pl/assets/img/tagger_static/tagger-h-tf-references-8ae09efcc24e2598273c7f8a5e802ac8-800.webp 800w, https://masiarek.pl/assets/img/tagger_static/tagger-h-tf-references-8ae09efcc24e2598273c7f8a5e802ac8-1200.webp 1200w, https://masiarek.pl/assets/img/tagger_static/tagger-h-tf-references-8ae09efcc24e2598273c7f8a5e802ac8-2000.webp 2000w"
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