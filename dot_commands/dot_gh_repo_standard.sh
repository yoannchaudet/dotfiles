# shellcheck shell=bash
#
# .gh_repo_standard.sh — single source of truth for my personal-repo
# standard. Sourced by new_gh_repo and audit_gh_repos.
#
# Defines:
#   OWNER                   — GitHub owner for all standardized repos
#   STANDARD_SETTINGS_JSON  — repo-level settings expected on every repo
#   STANDARD_RULESET_JSON   — default-branch ruleset payload to create
#   STANDARD_RULES          — required rule types (space-separated)
#   apply_settings <name>   — apply the standard settings to a repo
#   apply_ruleset  <name>   — create the standard ruleset on a repo

readonly OWNER="yoannchaudet"

readonly STANDARD_SETTINGS_JSON='{
  "delete_branch_on_merge": true,
  "allow_auto_merge": true,
  "allow_squash_merge": true,
  "allow_merge_commit": true,
  "allow_rebase_merge": true,
  "squash_merge_commit_title": "COMMIT_OR_PR_TITLE",
  "squash_merge_commit_message": "COMMIT_MESSAGES",
  "has_discussions": false,
  "has_wiki": false,
  "has_projects": false
}'

readonly STANDARD_RULESET_JSON='{
  "name": "default",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] }
  },
  "bypass_actors": [],
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    { "type": "copilot_code_review" },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false,
        "allowed_merge_methods": ["merge", "squash", "rebase"]
      }
    }
  ]
}'

readonly STANDARD_RULES="deletion non_fast_forward copilot_code_review pull_request"

# Apply the standard repo settings via a single PATCH.
apply_settings() {
  local name=$1
  local tmp
  tmp=$(mktemp -t gh_repo_settings.XXXXXX.json)
  # shellcheck disable=SC2064
  trap "rm -f '$tmp'" RETURN
  printf '%s' "$STANDARD_SETTINGS_JSON" >"$tmp"
  gum spin --title "Configuring repo settings on ${name}..." -- \
    gh api -X PATCH "repos/${OWNER}/${name}" --input "$tmp" >/dev/null
}

# Create the standard default-branch ruleset.
apply_ruleset() {
  local name=$1
  local tmp
  tmp=$(mktemp -t gh_repo_ruleset.XXXXXX.json)
  # shellcheck disable=SC2064
  trap "rm -f '$tmp'" RETURN
  printf '%s' "$STANDARD_RULESET_JSON" >"$tmp"
  gum spin --title "Applying default-branch ruleset on ${name}..." -- \
    gh api -X POST "repos/${OWNER}/${name}/rulesets" --input "$tmp" >/dev/null
}
