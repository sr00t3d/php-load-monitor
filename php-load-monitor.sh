#!/bin/bash
# -------------------------------------------------------------------------------
# Script: php_load_monitor.sh
# Version: 1.1
# Description: Monitors the server for a specific number of iterations (default 60)
#              to identify high CPU usage caused by PHP processes.
# -------------------------------------------------------------------------------

EMAIL=$1
OUTFILE="monitor_report.txt"
ITERATIONS=$2

# Get Server Details
# Using 'head -n 1' ensures we only get the primary IP if multiple exist
SERVER_IP=$(ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | head -n 1)
CURRENT_LOAD=$(uptime | awk -F'load average: ' '{print $2}')
HOSTNAME=$(hostname)

# Help Menu
if [[ "$1" =~ ^(-h|-H|--help)$ ]]; then
    echo -e "Usage:
    ./php_load_monitor.sh <EMAIL> [ITERATIONS]

Example:
    ./php_load_monitor.sh admin@example.com 10

Arguments:
    EMAIL       The recipient email address for the report.
    ITERATIONS  (Optional) Number of snapshots to take (Default: 60).
    "
    exit 0
fi

# Validation
if [[ -z "$EMAIL" ]]; then
    echo "Error: Email address is required."
    echo "Use -h for help."
    exit 1
fi

# Default iterations if not defined
if [[ -z "$ITERATIONS" ]]; then
    ITERATIONS="60"
fi

# Visual Header
echo "----------------------------------------------------------------"
echo " SERVER LOAD MONITOR - [${HOSTNAME}] [${SERVER_IP}]"
echo "----------------------------------------------------------------"
echo "Current Server Load: $CURRENT_LOAD"
echo "Starting monitoring for $ITERATIONS iterations..."
echo "A report will be sent to: $EMAIL"
echo "Please wait..."

# Start Monitoring and redirect output to file
{
    echo "Report Date: $(date)"
    echo "Server: $HOSTNAME ($SERVER_IP)"
    echo "---------------------------------------------------------------------------------------------"
    printf "%-8s | %-12s | %-50s | %-5s | %-10s\n" "PID" "USER" "SCRIPT/COMMAND" "%CPU" "TIME"
    echo "---------------------------------------------------------------------------------------------"

    for i in $(seq 1 "$ITERATIONS"); do
        # We filter for [p]hp to catch php-fpm, php-cgi, or cli scripts
        # We grab the first 50 chars of the command arguments to keep the log readable
        ps -eo user,pid,pcpu,etime,args --sort=-pcpu | grep '[p]hp' | while read -r user pid cpu etime cmd_args; do
            clean_cmd=$(echo "$cmd_args" | cut -c1-50)
            printf "%-8s | %-12s | %-50s | %-5s | %-10s\n" "$pid" "$user" "$clean_cmd" "$cpu" "$etime"
        done
        
        echo "- Snapshot $i of $ITERATIONS"
        
        # 0.5 second delay between snapshots
        sleep 0.5
    done
} > "$OUTFILE"

# Send Email
if command -v mail >/dev/null 2>&1; then
    mail -s "Load Monitor Report: $HOSTNAME" "$EMAIL" < "$OUTFILE"
    echo "Monitoring complete. Email sent."
else
    echo "Error: 'mail' command not found. Report saved to $OUTFILE"
    exit 1
fi

# Cleanup
rm -f "$OUTFILE"
