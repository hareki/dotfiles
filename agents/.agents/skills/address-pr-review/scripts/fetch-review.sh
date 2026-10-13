#!/usr/bin/env bash
# Print the open review feedback on a GitHub pull request as one JSON document.
#
# Usage: fetch-review.sh [<pr-url> | <pr-number>]
#
# With no argument, the pull request of the current branch is used. A URL
# anchored to one review comment (#discussion_r<id>, or #r<id> from the files
# tab), one review (#pullrequestreview-<id>) or one conversation comment
# (#issuecomment-<id>) narrows the output to that item.
#
# Resolved threads, hidden (minimized) comments, and dismissed or empty review
# bodies are left out, since none of them asks for anything anymore. An
# anchored thread or comment is kept regardless, because the link asked for it.

set -euo pipefail

die() {
  printf 'fetch-review: %s\n' "$*" >&2
  exit 1
}

for cmd in gh jq; do
  command -v "$cmd" >/dev/null || die "$cmd is not installed"
done

pr_url_re='^https://([^/]+)/([^/]+)/([^/]+)/pull/([0-9]+)([/?][^#]*)?(#(.*))?$'

input=${1:-}
if [[ ! $input =~ $pr_url_re ]]; then
  # A bare number (or nothing) is resolved against the current repo and branch
  url=$(gh pr view ${input:+"$input"} --json url --jq .url) ||
    die "no pull request found for ${input:-the current branch}"
  [[ $url =~ $pr_url_re ]] || die "unexpected pull request URL: $url"
fi
host=${BASH_REMATCH[1]} owner=${BASH_REMATCH[2]} repo=${BASH_REMATCH[3]}
number=${BASH_REMATCH[4]} anchor=${BASH_REMATCH[7]}

scope=pr target=0
if [[ $anchor =~ ^(discussion_)?r([0-9]+)$ ]]; then
  scope=thread target=${BASH_REMATCH[2]}
elif [[ $anchor =~ ^pullrequestreview-([0-9]+)$ ]]; then
  scope=review target=${BASH_REMATCH[1]}
elif [[ $anchor =~ ^issuecomment-([0-9]+)$ ]]; then
  scope=comment target=${BASH_REMATCH[1]}
elif [[ -n $anchor ]]; then
  printf 'fetch-review: ignoring unrecognized anchor #%s, fetching the whole pull request\n' "$anchor" >&2
fi

graphql() {
  gh api graphql --hostname "$host" -f owner="$owner" -f repo="$repo" -F number="$number" "$@"
}

# Every node of one pull request connection, one JSON object per line
nodes() {
  local connection=$1 fields=$2
  graphql --paginate --jq ".data.repository.pullRequest.$connection.nodes[]" -f query="
    query(\$owner: String!, \$repo: String!, \$number: Int!, \$endCursor: String) {
      repository(owner: \$owner, name: \$repo) {
        pullRequest(number: \$number) {
          $connection(first: 100, after: \$endCursor) {
            pageInfo { hasNextPage endCursor }
            nodes { $fields }
          }
        }
      }
    }"
}

author='author { login __typename }'

meta=$(graphql -f query='
  query($owner: String!, $repo: String!, $number: Int!) {
    viewer { login }
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $number) {
        url title state isDraft isCrossRepository
        author { login }
        baseRefName headRefName headRefOid
        headRepository { nameWithOwner }
      }
    }
  }')
threads=$(nodes reviewThreads "
  isResolved isOutdated path line startLine originalLine originalStartLine diffSide subjectType
  comments(first: 100) {
    totalCount
    nodes {
      databaseId url body createdAt diffHunk isMinimized $author
      originalCommit { oid }
      pullRequestReview { databaseId }
    }
  }")
reviews=$(nodes reviews "databaseId url state body submittedAt isMinimized $author")
comments=$(nodes comments "databaseId url body createdAt isMinimized $author")

jq -n \
  --argjson meta "$meta" \
  --slurpfile threads <(printf '%s\n' "$threads") \
  --slurpfile reviews <(printf '%s\n' "$reviews") \
  --slurpfile comments <(printf '%s\n' "$comments") \
  --arg scope "$scope" \
  --argjson target "$target" \
  --argjson number "$number" '
  def compact: with_entries(select(.value != null));
  def visible: select(.isMinimized | not);
  def has_body: .body | test("\\S");
  def who:
    if .author == null then "ghost"
    elif .author.__typename == "Bot" then "\(.author.login)[bot]"
    else .author.login end;

  # GitHub stores the hunk from its top down to the commented line, which for
  # a new file is the whole file up to there; only the tail is worth reading
  def hunk_tail($span): split("\n") | .[-([20, $span + 5] | max):] | join("\n");

  def comment:
    {id: .databaseId, url, author: who, createdAt, reviewId: .pullRequestReview.databaseId, body}
    | compact;

  def thread($keep_hidden):
    .comments.nodes[0] as $root
    | ((.originalLine // 0) - (.originalStartLine // .originalLine // 0) + 1) as $span
    | {
        path, line, startLine, originalLine, originalStartLine,
        side: .diffSide, subjectType, isOutdated, isResolved,
        originalCommit: $root.originalCommit.oid,
        diffHunk: (($root.diffHunk // "") | hunk_tail($span)),
        comments: [.comments.nodes[] | select($keep_hidden or (.isMinimized | not)) | comment],
        commentsNotFetched: (.comments.totalCount - (.comments.nodes | length) | if . > 0 then . else null end)
      }
    | compact
    | select(.comments | length > 0);

  def review: {id: .databaseId, url, author: who, state, submittedAt, body} | compact;

  def require($what): if length == 0 then error("no \($what) \($target) on this pull request") else . end;

  (if $scope == "thread" then {
      threads: ([$threads[] | select(any(.comments.nodes[]; .databaseId == $target))] | require("review comment") | map(thread(true))),
      reviews: [],
      comments: []
    }
  elif $scope == "review" then {
      threads: [$threads[] | select((.isResolved | not) and any(.comments.nodes[]; .pullRequestReview.databaseId == $target)) | thread(false)],
      reviews: ([$reviews[] | select(.databaseId == $target)] | require("review") | map(select(has_body) | review)),
      comments: []
    }
  elif $scope == "comment" then {
      threads: [],
      reviews: [],
      comments: ([$comments[] | select(.databaseId == $target)] | require("conversation comment") | map(comment))
    }
  else {
      threads: [$threads[] | select(.isResolved | not) | thread(false)],
      reviews: [$reviews[] | visible | select(.state != "DISMISSED" and .state != "PENDING" and has_body) | review],
      comments: [$comments[] | visible | comment],
      resolvedThreadsSkipped: ([$threads[] | select(.isResolved)] | length)
    }
  end) as $picked
  | {
      pr: ($meta.data.repository.pullRequest | {
        number: $number, url, title, state, isDraft, author: .author.login,
        baseRefName, headRefName, headRefOid, isCrossRepository,
        headRepository: .headRepository.nameWithOwner
      }),
      viewer: $meta.data.viewer.login,
      scope: $scope,
      threads: ($picked.threads | sort_by(.path, (.line // .originalLine // 0))),
      reviews: $picked.reviews,
      comments: $picked.comments,
      resolvedThreadsSkipped: $picked.resolvedThreadsSkipped
    }
  | compact
'
