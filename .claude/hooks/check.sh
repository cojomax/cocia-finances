#!/usr/bin/env bash
# PostToolUse hook: runs after Claude edits a file and checks the project that
# file belongs to. Exit 2 sends the output back to Claude so it fixes the problem.
#
#   .ts/.tsx/.js/.jsx/.mjs/.cjs/.css/.json  -> nearest package.json: npm lint + typecheck
#   .cs/.csproj/.props/.targets             -> nearest .csproj: dotnet build + dotnet format
#   .tf/.tfvars.example                     -> terraform fmt -check (+ validate if initialised)
#
# Anything else, or a missing tool, is skipped silently.

input=$(cat)
if command -v jq >/dev/null 2>&1; then
  file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
else
  file=$(printf '%s' "$input" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
fi
[ -z "$file" ] && exit 0
[ -f "$file" ] || exit 0

root="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Walk up from the edited file to the repo root, looking for a file matching a glob.
# Prints the directory that contains it.
find_up() {
  local pattern="$1" dir
  dir=$(dirname "$file")
  while :; do
    if compgen -G "$dir/$pattern" >/dev/null; then echo "$dir"; return 0; fi
    [ "$dir" = "$root" ] || [ "$dir" = "/" ] && return 1
    dir=$(dirname "$dir")
  done
}

fail() {  # $1 = project dir, $2 = output
  echo "Checks failed in $1 after editing $file:" >&2
  printf '%s\n' "$2" | tail -40 >&2
  exit 2
}

case "$file" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.css|*.json)
    dir=$(find_up package.json) || exit 0
    command -v npm >/dev/null 2>&1 || exit 0
    cd "$dir" || exit 0
    out=$( { npm run --silent --if-present lint && npm run --silent --if-present typecheck; } 2>&1 ) \
      || fail "$dir" "$out"
    ;;

  *.cs|*.csproj|*.props|*.targets)
    command -v dotnet >/dev/null 2>&1 || exit 0
    dir=$(find_up '*.csproj') || exit 0
    proj=$(compgen -G "$dir/*.csproj" | head -1)
    out=$(dotnet build "$proj" -nologo -v q -clp:"ErrorsOnly;NoSummary" 2>&1) \
      || fail "$dir" "dotnet build:"$'\n'"$out"
    case "$file" in
      *.cs)
        out=$(dotnet format "$proj" --verify-no-changes --no-restore --include "$file" 2>&1) \
          || fail "$dir" "dotnet format (run 'dotnet format $proj --include $file' to fix):"$'\n'"$out"
        ;;
    esac
    ;;

  *.tf)
    command -v terraform >/dev/null 2>&1 || exit 0
    dir=$(dirname "$file")
    out=$(terraform fmt -check -diff "$file" 2>&1) \
      || fail "$dir" "terraform fmt (run 'terraform fmt $file' to fix):"$'\n'"$out"
    # validate only works after 'terraform init'; skip until the directory is initialised
    if [ -d "$dir/.terraform" ]; then
      out=$(cd "$dir" && terraform validate -no-color 2>&1) || fail "$dir" "terraform validate:"$'\n'"$out"
    fi
    ;;
esac

exit 0
