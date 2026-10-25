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

read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
total=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle_total=$((idle + iowait))
usage=0
if [ -r "$cpu_file" ]; then
    read -r previous_total previous_idle < "$cpu_file"
    elapsed=$((total - previous_total))
    idle_elapsed=$((idle_total - previous_idle))
    if [ "$elapsed" -gt 0 ]; then
        usage=$(((100 * (elapsed - idle_elapsed) + elapsed / 2) / elapsed))
    fi
fi
printf '%s %s\n' "$total" "$idle_total" > "$cpu_file"

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

printf '{"text":" %2d%%","tooltip":"CPU: %d%% · 点击切换 GPU"}\n' "$usage" "$usage"
