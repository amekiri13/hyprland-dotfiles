#!/bin/sh

state_file="${XDG_RUNTIME_DIR:?}/waybar-memory-mode"
mode=gb
if [ -r "$state_file" ]; then
    IFS= read -r mode < "$state_file"
fi

if [ "${1:-}" = toggle ]; then
    if [ "$mode" = gb ]; then
        mode=percent
    else
        mode=gb
    fi
    printf '%s\n' "$mode" > "$state_file"
    exit
fi

awk -v mode="$mode" '
    $1 == "MemTotal:" { total = $2 }
    $1 == "MemAvailable:" { available = $2 }
    $1 == "SwapTotal:" { swap_total = $2 }
    $1 == "SwapFree:" { swap_free = $2 }
    END {
        if (total == 0) {
            print "{\"text\":\"RAM --\"}"
            exit
        }
        used = (total - available) / 1048576
        total_gb = total / 1048576
        percentage = used / total_gb * 100
        if (mode == "percent") {
            text = sprintf(" %.0f%%", percentage)
        } else {
            text = sprintf(" %.1fG", used)
        }
        if (swap_total > 0) {
            swap_used = (swap_total - swap_free) / 1048576
            swap_total_gb = swap_total / 1048576
            swap_percentage = (swap_total - swap_free) / swap_total * 100
            swap_text = sprintf("Swap: %.1fG / %.1fG (%.0f%%)", swap_used, swap_total_gb, swap_percentage)
        } else {
            swap_text = "Swap: 未启用"
        }
        printf "{\"text\":\"%s\",\"tooltip\":\"RAM: %.1fG / %.1fG (%.0f%%)\\n%s\"}\n", text, used, total_gb, percentage, swap_text
    }
' /proc/meminfo
