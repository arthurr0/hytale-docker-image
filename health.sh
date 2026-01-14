#!/bin/bash

if ! pgrep -f "HytaleServer" > /dev/null; then
    exit 1
fi

READY_FILE="/data/.server-ready"
if [ -f "$READY_FILE" ]; then
    exit 0
fi

LOG_FILE=$(find /data/logs -name "*.log" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
if [ -n "$LOG_FILE" ] && grep -q "Server started" "$LOG_FILE" 2>/dev/null; then
    touch "$READY_FILE"
    exit 0
fi

exit 1