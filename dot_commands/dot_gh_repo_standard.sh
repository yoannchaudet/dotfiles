# shellcheck shell=bash
#
# .gh_repo_standard.sh — single source of truth for my personal-repo
# standard. Sourced by new_gh_repo and audit_gh_repos.
#
# Defines:
#   OWNER                   — GitHub owner for all standardized repos
#   STANDARD_SETTINGS_JSON  — repo-level settings expected on every repo
#   standard_rules <visibility>         — required rule types
#   forbidden_rules <visibility>        — prohibited rule types
#   standard_ruleset_json <visibility>  — ruleset payload to create
#   apply_settings <name>   — apply the standard settings to a repo
#   apply_ruleset <name> <visibility>    — create the standard ruleset
#   remove_forbidden_rules <name> <visibility>
#                                         remove prohibited rules in place

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

standard_rules() {
  case "$1" in
    public)  echo "deletion non_fast_forward copilot_code_review pull_request" ;;
    private|internal) echo "deletion non_fast_forward pull_request" ;;
    *) return 1 ;;
  esac
}

forbidden_rules() {
  case "$1" in
    public)  echo "" ;;
    private|internal) echo "copilot_code_review" ;;
    *) return 1 ;;
  esac
}

standard_ruleset_json() {
  local visibility=$1
  local include_copilot=false
  [[ "$visibility" == "public" ]] && include_copilot=true

  jq -cn --argjson include_copilot "$include_copilot" '
    {
      name: "default",
      target: "branch",
      enforcement: "active",
      conditions: {
        ref_name: {include: ["~DEFAULT_BRANCH"], exclude: []}
      },
      bypass_actors: [],
      rules: (
        [{type: "deletion"}, {type: "non_fast_forward"}]
        + (if $include_copilot then [{type: "copilot_code_review"}] else [] end)
        + [{
          type: "pull_request",
          parameters: {
            required_approving_review_count: 0,
            dismiss_stale_reviews_on_push: false,
            require_code_owner_review: false,
            require_last_push_approval: false,
            required_review_thread_resolution: false,
            allowed_merge_methods: ["merge", "squash", "rebase"]
          }
        }]
      )
    }
  '
}

# Apply the standard repo settings via a single PATCH.
apply_settings() {
  local name=$1
  local tmp rc=0
  tmp=$(mktemp -t gh_repo_settings.XXXXXX.json)
  printf '%s' "$STANDARD_SETTINGS_JSON" >"$tmp"
  gum spin --title "Configuring repo settings on ${name}..." -- \
    gh api -X PATCH "repos/${OWNER}/${name}" --input "$tmp" >/dev/null || rc=$?
  rm -f "$tmp"
  return $rc
}

# Create the standard ruleset, or update it in place while preserving unrelated
# rules if a ruleset named "default" already exists.
apply_ruleset() {
  local name=$1
  local visibility=$2
  local rulesets_list id detail standard tmp rc=0

  if ! rulesets_list=$(gh api "repos/${OWNER}/${name}/rulesets?includes_parents=false"); then
    return 1
  fi
  if ! id=$(jq -r '.[] | select(.name == "default" and .target == "branch") | .id' \
    <<<"$rulesets_list" | head -n 1); then
    return 1
  fi
  if [[ -n "$id" ]]; then
    if ! detail=$(gh api "repos/${OWNER}/${name}/rulesets/$id"); then
      return 1
    fi
  fi
  if ! standard=$(standard_ruleset_json "$visibility"); then
    return 1
  fi
  if ! tmp=$(mktemp -t gh_repo_ruleset.XXXXXX.json); then
    return 1
  fi

  if [[ -n "$id" ]]; then
    if ! jq --argjson standard "$standard" '
      ($standard.rules | map(.type)) as $standard_types
      | $standard + {
          bypass_actors: (.bypass_actors // []),
          rules: (
            [.rules[] | select(.type as $type | $standard_types | index($type) | not)]
            + $standard.rules
          )
        }
    ' <<<"$detail" >"$tmp"; then
      rm -f "$tmp"
      return 1
    fi
    gum spin --title "Updating default-branch ruleset on ${name}..." -- \
      gh api -X PUT "repos/${OWNER}/${name}/rulesets/$id" --input "$tmp" >/dev/null || rc=$?
  else
    printf '%s' "$standard" >"$tmp"
    gum spin --title "Applying default-branch ruleset on ${name}..." -- \
      gh api -X POST "repos/${OWNER}/${name}/rulesets" --input "$tmp" >/dev/null || rc=$?
  fi
  rm -f "$tmp"
  return $rc
}

# Remove visibility-prohibited rules from active default-branch rulesets while
# preserving every other rule and its parameters.
remove_forbidden_rules() {
  local name=$1
  local visibility=$2
  local forbidden
  if ! forbidden=$(forbidden_rules "$visibility"); then
    return 1
  fi
  [[ -z "$forbidden" ]] && return 0

  local rulesets_list
  if ! rulesets_list=$(gh api "repos/${OWNER}/${name}/rulesets?includes_parents=false"); then
    return 1
  fi

  local id
  while read -r id; do
    [[ -z "$id" ]] && continue

    local detail
    detail=$(gh api "repos/${OWNER}/${name}/rulesets/$id" 2>/dev/null) || continue
    if ! jq -e '
      (.enforcement == "active") and
      (.target == "branch") and
      ((.conditions.ref_name.include // []) | index("~DEFAULT_BRANCH"))
    ' <<<"$detail" >/dev/null; then
      continue
    fi
    if ! jq -e --arg forbidden "$forbidden" '
      ($forbidden | split(" ")) as $types
      | any(.rules[]; .type as $type | $types | index($type))
    ' <<<"$detail" >/dev/null; then
      continue
    fi

    local tmp rc=0
    if ! tmp=$(mktemp -t gh_repo_ruleset.XXXXXX.json); then
      return 1
    fi
    if ! jq --arg forbidden "$forbidden" '
      ($forbidden | split(" ")) as $types
      | {
          name,
          target,
          enforcement,
          bypass_actors: (.bypass_actors // []),
          conditions,
          rules: [.rules[] | select(.type as $type | $types | index($type) | not)]
        }
    ' <<<"$detail" >"$tmp"; then
      rm -f "$tmp"
      return 1
    fi
    gum spin --title "Removing forbidden rules on ${name}..." -- \
      gh api -X PUT "repos/${OWNER}/${name}/rulesets/$id" --input "$tmp" >/dev/null || rc=$?
    rm -f "$tmp"
    [[ "$rc" -eq 0 ]] || return "$rc"
  done < <(jq -r '.[]?.id' <<<"$rulesets_list")
}
