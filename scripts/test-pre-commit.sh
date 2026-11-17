#!/bin/bash
# Tests for hooks/pre-commit's credential scan. Each case stages one file in
# a throwaway repository and runs the hook: a leak must block the commit, a
# known false positive must not.
#
# Usage: scripts/test-pre-commit.sh
set -u

HOOK="$(cd "$(dirname "$0")/.." && pwd)/hooks/pre-commit"
fail=0
pass=0

# Synthetic secrets are assembled at runtime, so this file holds none.
AWS="AK""IA""FAKE1234FAKE5678"
GENERIC="Zx9""kQ2mL7vB4nR8tY1wE6uI3oP5"

# expect <blocked|allowed> <name> <file content>
expect() {
  local want="$1" name="$2" content="$3"
  local repo
  repo="$(mktemp -d)"
  (
    cd "$repo" || exit 2
    git init -q
    printf '%s\n' "$content" > case.txt
    git add case.txt
    SKIP_SCAN_GITHOOK= bash "$HOOK" > /dev/null 2>&1
  )
  local code=$?
  rm -rf "$repo"
  local got=allowed
  [ "$code" -ne 0 ] && got=blocked
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "FAIL: $name: want $want, got $got"
  fi
}

# Real leaks stay blocked.
expect blocked "AWS access key" "key = $AWS"
expect blocked "generic token on its own line" "$GENERIC"
expect blocked "token assignment" "token = \"$GENERIC\""
expect blocked "bearer header" "Authorization: Bearer $GENERIC"

# False positives seen in practice.
expect allowed "TLA+ separator line" "-----------------------------------------------------------------------------"
expect allowed "markdown rule of equals signs" "========================================"
expect allowed "long snake_case identifier" "test_budget_excludes_time_spent_below_the_link"
expect allowed "long kebab-case name" "redact-secrets-example-plugin-readme"
expect allowed "an allowlisted line" "$GENERIC  # pragma: allowlist secret"
expect allowed "an empty placeholder value" 'token = "${TOKEN}"'
expect allowed "a redaction marker" 'token = "[REDACTED:assignment]"'

echo "pre-commit scan: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
