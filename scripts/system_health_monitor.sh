#!/usr/bin/env bash

# System Health Monitoring Script
# Monitors CPU, memory, disk usage, and running processes
# Sends alerts when thresholds are exceeded

# Configuration - Adjust thresholds as needed
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=80
LOG_FILE="/var/log/system_health_monitor.log"
ALERT_LOG_FILE="/var/log/system_health_alerts.log"

# Colors for console output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to log messages
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Function to send alert
send_alert() {
    local alert_type="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Log to console with color
    echo -e "${RED}[ALERT]${NC} [$timestamp] ${alert_type}: ${message}"

    # Log to alert file
    echo "[$timestamp] [ALERT] ${alert_type}: ${message}" | tee -a "$ALERT_LOG_FILE"
}

# Function to check CPU usage
check_cpu() {
    log_message "Checking CPU usage..."

    # Get CPU usage (average across all cores)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        cpu_usage=$(ps -A -o %cpu | awk '{s+=$1} END {print s}')
        cpu_usage=$(echo "$cpu_usage" | awk '{printf "%.0f", $1}')
    else
        # Linux
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        cpu_usage=$(echo "$cpu_usage" | awk '{printf "%.0f", $1}')
    fi

    log_message "CPU Usage: ${cpu_usage}%"

    if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
        send_alert "CPU" "CPU usage is ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"
        return 1
    else
        echo -e "${GREEN}[OK]${NC} CPU usage is normal: ${cpu_usage}%"
        return 0
    fi
}

# Function to check memory usage
check_memory() {
    log_message "Checking memory usage..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        memory_usage=$(ps -A -o %mem | awk '{s+=$1} END {print s}')
        memory_usage=$(echo "$memory_usage" | awk '{printf "%.0f", $1}')
    else
        # Linux
        memory_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    fi

    log_message "Memory Usage: ${memory_usage}%"

    if (( $(echo "$memory_usage > $MEMORY_THRESHOLD" | bc -l) )); then
        send_alert "MEMORY" "Memory usage is ${memory_usage}% (threshold: ${MEMORY_THRESHOLD}%)"
        return 1
    else
        echo -e "${GREEN}[OK]${NC} Memory usage is normal: ${memory_usage}%"
        return 0
    fi
}

# Function to check disk usage
check_disk() {
    log_message "Checking disk usage..."

    # Check all mounted filesystems
    local alert_sent=0

    while IFS= read -r line; do
        filesystem=$(echo "$line" | awk '{print $1}')
        usage=$(echo "$line" | awk '{print $5}' | sed 's/%//')
        mountpoint=$(echo "$line" | awk '{print $6}')

        log_message "Disk Usage on ${mountpoint} (${filesystem}): ${usage}%"

        if (( usage > DISK_THRESHOLD )); then
            send_alert "DISK" "Disk usage on ${mountpoint} is ${usage}% (threshold: ${DISK_THRESHOLD}%)"
            alert_sent=1
        else
            echo -e "${GREEN}[OK]${NC} Disk usage on ${mountpoint} is normal: ${usage}%"
        fi
    done < <(df -h | grep -E "^/dev/" | grep -v "tmpfs")

    return $alert_sent
}

# Function to check running processes
check_processes() {
    log_message "Checking running processes..."

    # Get number of running processes
    if [[ "$OSTYPE" == "darwin"* ]]; then
        process_count=$(ps -ax | wc -l)
    else
        process_count=$(ps aux | wc -l)
    fi

    log_message "Total running processes: ${process_count}"
    echo -e "${GREEN}[OK]${NC} Total running processes: ${process_count}"

    # Show top 5 CPU-consuming processes
    log_message "Top 5 CPU-consuming processes:"
    echo -e "\n${YELLOW}Top 5 CPU-consuming processes:${NC}"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        ps -Ao comm,%cpu | sort -k2 -rn | head -6 | tail -5 | while read proc cpu; do
            echo "  - $proc: ${cpu}%"
            log_message "  - $proc: ${cpu}%"
        done
    else
        ps aux --sort=-%cpu | awk 'NR<=6 && NR>1 {printf "  - %s: %.1f%%\n", $11, $3}' | while read line; do
            echo "$line"
            log_message "$line"
        done
    fi

    # Show top 5 memory-consuming processes
    log_message "Top 5 memory-consuming processes:"
    echo -e "\n${YELLOW}Top 5 memory-consuming processes:${NC}"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        ps -Ao comm,%mem | sort -k2 -rn | head -6 | tail -5 | while read proc mem; do
            echo "  - $proc: ${mem}%"
            log_message "  - $proc: ${mem}%"
        done
    else
        ps aux --sort=-%mem | awk 'NR<=6 && NR>1 {printf "  - %s: %.1f%%\n", $11, $4}' | while read line; do
            echo "$line"
            log_message "$line"
        done
    fi
}

# Function to create log files if they don't exist
initialize_logs() {
    for log in "$LOG_FILE" "$ALERT_LOG_FILE"; do
        if [[ ! -f "$log" ]]; then
            # Try to create in /var/log, fallback to current directory if no permissions
            if ! touch "$log" 2>/dev/null; then
                log_dir="./logs"
                mkdir -p "$log_dir"
                log_file="$log_dir/$(basename $log)"
                if [[ "$log" == "$LOG_FILE" ]]; then
                    LOG_FILE="$log_file"
                else
                    ALERT_LOG_FILE="$log_file"
                fi
            fi
        fi
    done
}

# Main function
main() {
    echo -e "\n${YELLOW}========================================${NC}"
    echo -e "${YELLOW}  System Health Monitoring - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${YELLOW}========================================${NC}\n"

    # Initialize log files
    initialize_logs

    log_message "=== System Health Check Started ==="
    log_message "Thresholds: CPU=${CPU_THRESHOLD}%, Memory=${MEMORY_THRESHOLD}%, Disk=${DISK_THRESHOLD}%"

    # Run all checks
    check_cpu
    cpu_status=$?

    echo ""
    check_memory
    memory_status=$?

    echo ""
    check_disk
    disk_status=$?

    echo ""
    check_processes

    # Summary
    echo -e "\n${YELLOW}========================================${NC}"
    if [[ $cpu_status -eq 0 && $memory_status -eq 0 && $disk_status -eq 0 ]]; then
        echo -e "${GREEN}[OK] System health is GOOD${NC}"
        log_message "=== System Health Check Completed: GOOD ==="
    else
        echo -e "${RED}[WARN] System health ALERTS detected - check alert log${NC}"
        log_message "=== System Health Check Completed: ALERTS DETECTED ==="
    fi
    echo -e "${YELLOW}========================================${NC}\n"

    echo "Log files:"
    echo "  - Main log: $LOG_FILE"
    echo "  - Alert log: $ALERT_LOG_FILE"
}

# Run main function
main
