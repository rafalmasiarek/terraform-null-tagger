data "external" "module_origin" {
  count = var.detect_origin ? 1 : 0

  # program is relative to working_dir, not to the caller's cwd - do not
  # prefix it with path.module here, that double-relativizes the path.
  program     = ["bash", "scripts/detect_origin.sh"]
  working_dir = path.module
  query       = {}
}
