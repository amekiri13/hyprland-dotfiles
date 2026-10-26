#!/bin/sh

runtime_dir="${XDG_RUNTIME_DIR:?}"
mode_file="$runtime_dir/waybar-compute-mode"
cpu_file="$runtime_dir/waybar-compute-cpu"
mode=cpu
if [ -r "$mode_file" ]; then
    IFS= read -r mode < "$mode_file"
fi

if [ "${1:-}" = toggle ]; then
    if [ "$mode" = cpu ]; then
        mode=gpu
    else
        mode=cpu
    fi
    printf '%s\n' "$mode" > "$mode_file"
    exit
fi

cpu_json=$(awk -v state_file="$cpu_file" '
    BEGIN {
        while ((getline line < state_file) > 0) {
            split(line, previous, " ")
            old_total[previous[1]] = previous[2]
            old_idle[previous[1]] = previous[3]
        }
        close(state_file)
    }
    $1 ~ /^cpu[0-9]*$/ {
        total = $2 + $3 + $4 + $5 + $6 + $7 + $8 + $9
        idle = $5 + $6
        elapsed = total - old_total[$1]
        idle_elapsed = idle - old_idle[$1]
        usage = ($1 in old_total && elapsed > 0) ? int(100 * (elapsed - idle_elapsed) / elapsed + 0.5) : 0
        printf "%s %.0f %.0f\n", $1, total, idle > state_file

        if ($1 == "cpu") {
            overall = usage
        } else {
            core = substr($1, 4)
            cores[core] = usage
            ids[count++] = core
        }
    }
    END {
        tooltip = sprintf("CPU: %d%%", overall)
        half = int((count + 1) / 2)
        for (i = 0; i < half; i++) {
            left = ids[i]
            tooltip = tooltip sprintf("\\nCPU%02d: %3d%%", left, cores[left])
            if (i + half < count) {
                right = ids[i + half]
                tooltip = tooltip sprintf("    CPU%02d: %3d%%", right, cores[right])
            }
        }
        printf "{\"text\":\" %2d%%\",\"tooltip\":\"%s\"}\n", overall, tooltip
    }
' /proc/stat)

if [ "$mode" = gpu ]; then
    for card in /sys/class/drm/card[0-9]*; do
        [ -r "$card/device/vendor" ] || continue
        IFS= read -r vendor < "$card/device/vendor"
        [ "$vendor" = 0x10de ] || continue

        status_file="$card/device/power/runtime_status"
        if [ -r "$status_file" ]; then
            IFS= read -r status < "$status_file"
            case "$status" in
                suspended|suspending)
                    printf '{"text":"󰢮 休眠","tooltip":"NVIDIA GPU: 休眠 · 点击切换 CPU"}\n'
                    exit
                    ;;
            esac
        fi

        usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null) || usage=
        case "$usage" in
            ''|*[!0-9]*) break ;;
        esac
        printf '{"text":"󰢮 %2d%%","tooltip":"NVIDIA GPU: %d%% · 点击切换 CPU"}\n' "$usage" "$usage"
        exit
    done
    printf '{"text":"󰢮 不可用","tooltip":"NVIDIA GPU: 不可用 · 点击切换 CPU"}\n'
    exit
fi

printf '%s\n' "$cpu_json"
