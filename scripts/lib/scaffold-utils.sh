#!/bin/bash
# Shared helper — source this in each scaffold script

safe_file() {
  local target="$1"
  local dir=$(dirname "$target")
  local base=$(basename "$target")

  # Already in the right place — skip
  if [ -f "$target" ]; then
    echo "  ✓ exists:      $target"
    return
  fi

  # Placeholder already exists — skip
  if [ -f "$dir/.$base" ]; then
    echo "  ✓ placeholder: $dir/.$base"
    return
  fi

  # Reorganize: file exists at app root — move it
  if [ -f "$ROOT/$base" ]; then
    mkdir -p "$dir"
    mv "$ROOT/$base" "$target"
    echo "  → moved:       $ROOT/$base → $target"
    return
  fi

  # Reorganize: file exists at src/ root — move it
  if [ -f "$ROOT/src/$base" ] && [ "$dir" != "$ROOT/src" ]; then
    mkdir -p "$dir"
    mv "$ROOT/src/$base" "$target"
    echo "  → moved:       src/$base → $target"
    return
  fi

  # New file — create dot-prefixed placeholder
  mkdir -p "$dir"
  echo "." > "$dir/.$base"
  echo "  + created:     $dir/.$base"
}
