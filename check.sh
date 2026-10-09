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

show() {
  local label="$1"
  shift
  printf '\n== %s ==\n' "$label"
  $fetch -s -D - -o /tmp/check-body "$@" \
    | grep -i -E '^(HTTP/|x-proxy-ran|x-next-proxy-ran|set-cookie|location|x-matched-path|x-vercel-id|x-vercel-error|x-vercel-cache)' \
    | tr -d '\r'
  printf 'body: %s\n' "$(head -c 160 /tmp/check-body | tr '\n' ' ')"
}

show 'GET /' "$base/"
show 'GET /from-proxy' "$base/from-proxy"
show 'GET /protected (no cookie)' "$base/protected"
show 'GET /protected (session cookie)' "$base/protected" -H 'Cookie: session=1'
show 'GET /api/hello' "$base/api/hello"
show 'GET /web-proxy-check' "$base/web-proxy-check"
