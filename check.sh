#!/usr/bin/env bash
# Usage: ./check.sh <deployment-url> [fetch-command]
#
# Prints, for each path in the matrix, the status line and the headers that
# tell which layer handled the request. Preview deployments are protected by
# Vercel Authentication, so the default fetch command is `vercel curl`; pass
# `curl` for an unprotected production URL.
set -u

base="${1:?usage: ./check.sh <deployment-url> [fetch-command]}"
fetch="${2:-vercel curl}"
body_file="$(mktemp)"

# `vercel curl <url> -- <curl options>`; plain curl takes the options directly.
separator='--'
[ "$fetch" = 'curl' ] && separator=''

show() {
  local label="$1"
  local path="$2"
  shift 2
  printf '\n== %s ==\n' "$label"
  $fetch "$base$path" $separator -s -D - -o "$body_file" "$@" \
    | grep -i -E '^(HTTP/|x-proxy-ran|x-next-proxy-ran|set-cookie|location|x-matched-path|x-vercel-id|x-vercel-error|x-vercel-cache)' \
    | tr -d '\r'
  printf 'body: %s\n' "$(head -c 200 "$body_file" | tr '\n' ' ')"
}

show 'GET /' /
show 'GET /from-proxy' /from-proxy
show 'GET /protected (no cookie)' /protected
show 'GET /protected (session cookie)' /protected -H 'Cookie: session=1'
show 'GET /api/hello' /api/hello
show 'GET /web-proxy-check' /web-proxy-check
