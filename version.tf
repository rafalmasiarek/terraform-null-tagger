# Bumped by hand (or a release script) immediately before cutting a new git
# tag, so this file always reflects the version it ships in - same
# self-stamping approach as origin_source/origin_version, since a module
# has no supported way to read back the ref/version its own caller used.
locals {
  tagger_module_version = "0.2.0"
}
