#!/usr/bin/env bash

# Application Health Checker Script
# Checks application uptime and health by monitoring HTTP status codes
# Determines if application is 'up' (functioning) or 'down' (unavailable)

# Configuration
TIMEOUT=10  # Timeout in seconds for HTTP requests
LOG_FILE="/var/log/app_health_checker.log"
STATUS_FILE="/var/log/app_health_status.log"

# Colors for console output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Function to save status
save_status() {
    local url="$1"
    local status="$2"
    local http_code="$3"
    local response_time="$4"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] $url | Status: $status | HTTP: $http_code | Response Time: ${response_time}ms" >> "$STATUS_FILE"
}

# Function to check application health
check_application() {
    local url="$1"
    local app_name="${2:-$(echo $url | sed 's|https\?://||' | cut -d/ -f1)}"

    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Checking: ${YELLOW}$app_name${NC}"
    echo -e "${BLUE}URL: ${NC}$url"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    log_message "Checking application: $app_name ($url)"

    # Perform HTTP request and capture status code and response time
    if command -v curl &> /dev/null; then
        # Use curl with time measurement
        response=$(curl -s -o /dev/null -w "%{http_code}:%{time_total}" --connect-timeout "$TIMEOUT" --max-time "$TIMEOUT" "$url" 2>&1)
        http_code=$(echo "$response" | cut -d: -f1)
        local response_time_sec=$(echo "$response" | cut -d: -f2)
        # Convert to milliseconds
        local response_time=$(echo "$response_time_sec * 1000" | bc | cut -d. -f1)
    else
        echo -e "${RED}[ERROR] curl is not installed${NC}"
        log_message "Error: curl is not installed"
        return 1
    fi

    # Determine application status based on HTTP code
    local status="DOWN"
    local status_color=$RED
    local symbol="[FAIL]"

    if [[ "$http_code" =~ ^[0-9]+$ ]]; then
        case $http_code in
            200|201|202|204)
                status="UP"
                status_color=$GREEN
                symbol="[OK]"
                ;;
            301|302|307|308)
                status="UP (REDIRECT)"
                status_color=$YELLOW
                symbol="[WARN]"
                ;;
            400|401|403|404|405)
                status="UP (CLIENT ERROR)"
                status_color=$YELLOW
                symbol="[WARN]"
                ;;
            500|502|503|504)
                status="DOWN (SERVER ERROR)"
                status_color=$RED
                symbol="[FAIL]"
                ;;
            *)
                if [[ $http_code -ge 200 && $http_code -lt 300 ]]; then
                    status="UP"
                    status_color=$GREEN
                    symbol="[OK]"
                elif [[ $http_code -ge 300 && $http_code -lt 400 ]]; then
                    status="UP (REDIRECT)"
                    status_color=$YELLOW
                    symbol="[WARN]"
                else
                    status="DOWN"
                    status_color=$RED
                    symbol="[FAIL]"
                fi
                ;;
        esac
    else
        # Connection error or timeout
        status="DOWN (TIMEOUT/UNREACHABLE)"
        http_code="N/A"
        response_time="N/A"
        status_color=$RED
        symbol="[FAIL]"
    fi

    # Display results
    echo -e "\n${YELLOW}Results:${NC}"
    echo -e "  Status:        ${status_color}${symbol} ${status}${NC}"
    echo -e "  HTTP Code:     ${http_code}"
    echo -e "  Response Time: ${response_time} ms"

    # Log results
    log_message "Results: Status=$status, HTTP=$http_code, ResponseTime=${response_time}ms"
    save_status "$url" "$status" "$http_code" "$response_time"

    # Return status
    if [[ "$status" == "UP" || "$status" == "UP (REDIRECT)" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check multiple applications
check_multiple_applications() {
    local urls=("$@")
    local total=${#urls[@]}
    local up_count=0
    local down_count=0

    echo -e "\n${YELLOW}========================================${NC}"
    echo -e "${YELLOW}  Application Health Checker - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}Checking $total application(s)...${NC}"

    for url in "${urls[@]}"; do
        check_application "$url"
        if [[ $? -eq 0 ]]; then
            ((up_count++))
        else
            ((down_count++))
        fi
    done

    # Summary
    echo -e "\n${YELLOW}========================================${NC}"
    echo -e "${YELLOW}Summary:${NC}"
    echo -e "  Total Applications: $total"
    echo -e "  ${GREEN}UP:${NC}   $up_count"
    echo -e "  ${RED}DOWN:${NC} $down_count"
    echo -e "${YELLOW}========================================${NC}\n"

    log_message "Summary: Total=$total, UP=$up_count, DOWN=$down_count"

    echo "Log files:"
    echo "  - Health check log: $LOG_FILE"
    echo "  - Status history:   $STATUS_FILE"

    if [[ $down_count -gt 0 ]]; then
        return 1
    else
        return 0
    fi
}

# Function to initialize log files
initialize_logs() {
    for log in "$LOG_FILE" "$STATUS_FILE"; do
        if [[ ! -f "$log" ]]; then
            # Try to create in /var/log, fallback to current directory if no permissions
            if ! touch "$log" 2>/dev/null; then
                log_dir="./logs"
                mkdir -p "$log_dir"
                log_file="$log_dir/$(basename $log)"
                if [[ "$log" == "$LOG_FILE" ]]; then
                    LOG_FILE="$log_file"
                else
                    STATUS_FILE="$log_file"
                fi
            fi
        fi
    done
}

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS] <URL> [URL2] [URL3] ...

Application Health Checker - Monitors application uptime via HTTP status codes

OPTIONS:
    -t, --timeout SECONDS    Set timeout for HTTP requests (default: 10)
    -h, --help               Display this help message

EXAMPLES:
    # Check single application
    $0 https://example.com

    # Check multiple applications
    $0 https://api.example.com https://www.example.com https://admin.example.com

    # Check with custom timeout
    $0 -t 5 https://slow-app.example.com

HTTP STATUS CODES:
    2xx (200, 201, etc.)     - Application is UP
    3xx (301, 302, etc.)     - Application is UP (with redirect)
    4xx (400, 404, etc.)     - Application is UP but client error
    5xx (500, 502, etc.)     - Application is DOWN (server error)
    Timeout/No response      - Application is DOWN (unreachable)

EOF
}

# Main function
main() {
    # Initialize log files
    initialize_logs

    # Parse arguments
    urls=()
    while [[ $# -gt 0 ]]; do
        case $1 in
            -t|--timeout)
                TIMEOUT="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                echo -e "${RED}Error: Unknown option $1${NC}"
                usage
                exit 1
                ;;
            *)
                urls+=("$1")
                shift
                ;;
        esac
    done

    # Check if at least one URL provided
    if [[ ${#urls[@]} -eq 0 ]]; then
        echo -e "${RED}Error: No URL provided${NC}\n"
        usage
        exit 1
    fi

    # Check applications
    check_multiple_applications "${urls[@]}"
    exit $?
}

# Run main function
main "$@"
