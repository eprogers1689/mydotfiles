#!/bin/bash

if [[ "$(uname)" == "Darwin" ]]; then
    pmset -g ps  |  sed -n 's/.*[[:blank:]]+*\(.*%\).*/\1/p'
else
    echo "$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)%"
fi
