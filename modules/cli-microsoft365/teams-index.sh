#!/usr/bin/env bash
# Prints every Teams chat and channel the user belongs to as JSON lines, from a local cache.
# Chats refresh incrementally (newest activity first); channels rebuild daily. --refresh rebuilds both.
set -euo pipefail

dir="${XDG_CACHE_HOME:-$HOME/.cache}/teams-index"
chats="$dir/chats.ndjson"
channels="$dir/channels.ndjson"
mkdir -p "$dir"

usage="usage: teams-index [--refresh]
Prints one JSON object per line: {kind: \"chat\"|\"channel\", id, name, type, webUrl, ...}.
Chats also have members (display names) and last (last message time); channels have team and teamId.
--refresh rebuilds the whole cache (about a minute); without it, chats update incrementally."

refresh=false
case ${1:-} in
  "") ;;
  --refresh) refresh=true ;;
  -h | --help) echo "$usage"; exit 0 ;;
  *) echo "$usage" >&2; exit 2 ;;
esac

tmp=$(mktemp -d "$dir/.tmp.XXXXXX")
trap 'rm -rf "$tmp"' EXIT

# Pages a Graph collection, printing .value[] as JSON lines. Stops early once a page ends before $2.
page() {
  local url=$1 since=${2:-} resp
  while [[ -n $url ]]; do
    resp=$(m365 request --url "$url")
    jq -c '.value[]' <<<"$resp"
    if [[ -n $since ]] && jq -e --arg s "$since" \
      '(.value | last | .lastMessagePreview.createdDateTime // "") < $s' <<<"$resp" >/dev/null; then
      break
    fi
    url=$(jq -r '."@odata.nextLink" // empty' <<<"$resp")
  done
}

chat_url='@graph/me/chats?$expand=members,lastMessagePreview&$orderby=lastMessagePreview/createdDateTime desc&$top=50'
to_chat='{kind: "chat", id, name: .topic, type: .chatType, members: [.members[].displayName],
  last: .lastMessagePreview.createdDateTime, webUrl}'

if [[ $refresh == false && -s $chats ]]; then
  since=$(jq -rs 'map(.last // "") | max' "$chats")
  { page "$chat_url" "$since" | jq -c "$to_chat"; cat "$chats"; } |
    jq -cs 'group_by(.id) | map(.[0]) | sort_by(.last // "") | reverse | .[]' >"$tmp/chats"
else
  echo "teams-index: indexing all chats (about a minute)..." >&2
  page "$chat_url" | jq -c "$to_chat" | jq -cs 'unique_by(.id) | sort_by(.last // "") | reverse | .[]' >"$tmp/chats"
fi
mv "$tmp/chats" "$chats"

if [[ $refresh == true || ! -s $channels || -n $(find "$channels" -mmin +1440) ]]; then
  echo "teams-index: indexing team channels..." >&2
  page '@graph/me/joinedTeams?$select=id,displayName' |
    while read -r team; do
      id=$(jq -r .id <<<"$team")
      page "@graph/teams/$id/allChannels?\$select=id,displayName,membershipType,webUrl" |
        jq -c --argjson t "$team" '{kind: "channel", id, name: .displayName, type: .membershipType,
          team: $t.displayName, teamId: $t.id, webUrl}'
    done >"$tmp/channels"
  mv "$tmp/channels" "$channels"
fi

cat "$chats" "$channels"
