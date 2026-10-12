#!/usr/bin/env bash
# Best-effort detection of this module's own source/version, read back from
# Terraform's internal .terraform/modules/modules.json (undocumented, but
# stable in practice since Terraform 0.11+). This is deliberately NOT a
# documented/public Terraform mechanism - there is no supported way for a
# module to introspect the source/version its caller used. This script must
# never fail: any error here falls back to "unknown" rather than breaking
# the caller's plan/apply, since this is optional metadata, not a hard
# requirement for the rest of the module to work.
#
# Invoked with working_dir = path.module, so $PWD is this module's own
# checkout directory, e.g. .terraform/modules/<key>.

set -uo pipefail

fallback='{"source":"unknown","version":"unknown"}'

self_dir="$PWD"
search_dir="$self_dir"
modules_json=""

for _ in 1 2 3 4 5; do
  candidate="$search_dir/modules.json"
  if [[ -f "$candidate" ]]; then
    modules_json="$candidate"
    break
  fi
  search_dir="$(dirname "$search_dir")"
done

if [[ -z "$modules_json" ]] || ! command -v jq >/dev/null 2>&1; then
  echo "$fallback"
  exit 0
fi

result=$(jq -c --arg dir "$self_dir" '
  .Modules[]
  | select(.Dir == $dir or ($dir | endswith(.Dir)))
  | {source: (.Source // "unknown"), version: (.Version // "unknown")}
' "$modules_json" 2>/dev/null | head -n1)

if [[ -z "$result" ]]; then
  echo "$fallback"
else
  echo "$result"
fi
