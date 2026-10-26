#!/bin/sh
# Keep the Dunst history-only rule in sync with OBS across all launch methods.

runtime_dir=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
exec 9>"$runtime_dir/obs-dunst-quiet.lock"
flock -n 9 || exit 0

uid=$(id -u)
trap 'dunstctl rule obs_quiet disable >/dev/null 2>&1' EXIT

while :; do
    if pgrep -u "$uid" -x obs >/dev/null; then
        dunstctl rule obs_quiet enable >/dev/null 2>&1
    else
        dunstctl rule obs_quiet disable >/dev/null 2>&1
    fi
    sleep 2
done
