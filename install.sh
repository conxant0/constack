#!/usr/bin/env bash
# install.sh: copy the workflow into ~/.claude. Never overwrites a file you already have.
set -eu
src=$(cd "$(dirname "$0")" && pwd); dst=~/.claude
mkdir -p "$dst/skills"

for s in "$src"/skills/*/; do
  name=$(basename "$s")
  if [ -e "$dst/skills/$name" ]; then echo "skip skills/$name (already exists)"
  else cp -R "$s" "$dst/skills/$name"; echo "added skills/$name"; fi
done
chmod +x "$dst"/skills/build/scripts/{wf,afk-loop,check-red-green.sh} 2>/dev/null || true

copy() { # copy <repo file> <target>
  if [ -e "$2" ]; then echo "skip $2 (exists): merge $src/$1 by hand"
  else cp "$src/$1" "$2"; echo "added $2"; fi
}
copy statusline.js "$dst/statusline.js"
copy settings.example.json "$dst/settings.json"
copy CLAUDE.md "$dst/CLAUDE.md"
