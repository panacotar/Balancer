#!/usr/bin/env bash
# Sets one KEY=value line in .env.production without sourcing the file.
set_env_value() {
  key=$1
  value=$2
  file=$3
  tmp=$(mktemp)
  found=0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      "${key}="*)
        printf '%s=%s\n' "$key" "$value"
        found=1
        ;;
      *)
        printf '%s\n' "$line"
        ;;
    esac
  done < "$file" > "$tmp"
  if [ "$found" -eq 0 ]; then
    printf '%s=%s\n' "$key" "$value" >> "$tmp"
  fi
  mv "$tmp" "$file"
  chmod 600 "$file"
}
