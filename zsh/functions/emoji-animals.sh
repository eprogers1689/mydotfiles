_copy_random_emoji_animal() {
  local image
  local quick_look_pid

  image=$(find "$1" -maxdepth 1 -type f -name '*.png' | awk '
    BEGIN { srand() }
    { if (rand() < 1 / ++count) selected = $0 }
    END { print selected }
  ')

  if [[ -z "$image" ]]; then
    printf 'No emoji animals found in %s\n' "$1" >&2
    return 1
  fi

  osascript - "$image" <<'APPLESCRIPT'
on run argv
  set the clipboard to (read (POSIX file (item 1 of argv)) as «class PNGf»)
end run
APPLESCRIPT

  qlmanage -p "$image" >/dev/null 2>&1 &
  quick_look_pid=$!
  (sleep 2; kill "$quick_look_pid" 2>/dev/null) &
}

up() {
  _copy_random_emoji_animal "$HOME/Documents/emoji-animals/thumbs-up"
}

down() {
  _copy_random_emoji_animal "$HOME/Documents/emoji-animals/thumbs-down"
}

pop() {
  _copy_random_emoji_animal "$HOME/Documents/emoji-animals/popper"
}
