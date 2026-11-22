#!/usr/bin/env bash
# Runs after Claude edits a file. Finds the nearest package.json above the
# edited file and runs its lint + typecheck scripts if they exist.
# Exit 2 sends the error output back to Claude so it fixes the problem itself.
# Does nothing until a project with a package.json exists.

input=$(cat)
file=$(printf '%s' "$input" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
[ -z "$file" ] && exit 0

dir=$(dirname "$file")
root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
while [ "$dir" != "/" ] && [ ! -f "$dir/package.json" ]; do
  [ "$dir" = "$root" ] && break
  dir=$(dirname "$dir")
done
[ -f "$dir/package.json" ] || exit 0

cd "$dir" || exit 0
out=$( { npm run --silent --if-present lint && npm run --silent --if-present typecheck; } 2>&1 )
if [ $? -ne 0 ]; then
  echo "Checks failed in $dir after editing $file:" >&2
  echo "$out" | tail -40 >&2
  exit 2
fi
exit 0
