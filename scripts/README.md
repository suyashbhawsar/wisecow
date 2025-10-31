# Monitoring Scripts

This directory contains two monitoring scripts developed as part of Problem Statement 2.

## 1. System Health Monitor (`system_health_monitor.sh`)

A comprehensive system health monitoring script that checks CPU usage, memory usage, disk space, and running processes.

### Features

- **CPU Monitoring**: Tracks CPU usage across all cores
- **Memory Monitoring**: Monitors RAM usage percentage
- **Disk Monitoring**: Checks disk usage for all mounted filesystems
- **Process Monitoring**: Lists total running processes and top consumers
- **Alert System**: Logs alerts to console and files when thresholds are exceeded
- **Configurable Thresholds**: Easily adjust warning thresholds

### Usage

```bash
./system_health_monitor.sh
```

### Configuration

Edit the script to adjust thresholds:
```bash
CPU_THRESHOLD=80        # Alert when CPU > 80%
MEMORY_THRESHOLD=80     # Alert when Memory > 80%
DISK_THRESHOLD=80       # Alert when Disk > 80%
```

### Output

The script generates:
- Console output with color-coded status
- `system_health_monitor.log` - Main activity log
- `system_health_alerts.log` - Alert-only log

### Example Output

```
========================================
  System Health Monitoring - 2025-10-31 16:30:57
========================================

[OK] CPU usage is normal: 45%
[OK] Memory usage is normal: 77%
[OK] Disk usage on / is normal: 52%

Top 5 CPU-consuming processes:
  - chrome: 45.2%
  - node: 26.5%
  - docker: 20.9%

========================================
[OK] System health is GOOD
========================================
```

---

## 2. Application Health Checker (`app_health_checker.sh`)

Monitors application uptime and health by checking HTTP status codes. Determines if applications are 'up' (functioning) or 'down' (unavailable).

### Features

- **HTTP Status Checking**: Verifies application accessibility via HTTP/HTTPS
- **Response Time Measurement**: Tracks application response times
- **Multiple App Support**: Check multiple applications in one run
- **Detailed Status**: Distinguishes between different types of errors
- **Timeout Handling**: Configurable timeout for slow applications
- **Status History**: Maintains log of all health checks

### Usage

```bash
# Check single application
./app_health_checker.sh https://example.com

# Check multiple applications
./app_health_checker.sh https://api.example.com https://www.example.com

# Check with custom timeout (in seconds)
./app_health_checker.sh -t 5 https://slow-app.example.com

# Display help
./app_health_checker.sh --help
```

### HTTP Status Code Interpretation

| Status Code | Application Status | Description |
|-------------|-------------------|-------------|
| 2xx (200, 201, etc.) | UP | Application is functioning normally |
| 3xx (301, 302, etc.) | UP (REDIRECT) | Application is up but redirecting |
| 4xx (400, 404, etc.) | UP (CLIENT ERROR) | Application is up but client error |
| 5xx (500, 502, etc.) | DOWN (SERVER ERROR) | Application has server-side issues |
| Timeout/No response | DOWN (UNREACHABLE) | Application is not responding |

### Output

The script generates:
- Console output with color-coded status and response times
- `app_health_checker.log` - Detailed health check log
- `app_health_status.log` - Status history for tracking

### Example Output

```
========================================
  Application Health Checker - 2025-10-31 16:33:04
========================================
Checking 3 application(s)...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Checking: wisecow
URL: http://34.93.177.251
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Results:
  Status:        [OK] UP
  HTTP Code:     200
  Response Time: 119 ms

========================================
Summary:
  Total Applications: 3
  UP:   2
  DOWN: 1
========================================
```

---

## Requirements

Both scripts require:
- **Bash**: Version 4.0 or higher
- **curl**: For HTTP requests (app_health_checker.sh)
- **bc**: For floating-point arithmetic

### Installing Requirements

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install curl bc
```

**macOS:**
```bash
brew install curl bc
```

**RHEL/CentOS:**
```bash
sudo yum install curl bc
```

---

## Automation

### Run System Health Monitor Every 5 Minutes

Add to crontab:
```bash
*/5 * * * * /path/to/system_health_monitor.sh >> /var/log/health_monitor_cron.log 2>&1
```

### Run Application Health Checker Hourly

Add to crontab:
```bash
0 * * * * /path/to/app_health_checker.sh https://your-app.com >> /var/log/app_health_cron.log 2>&1
```

---

## Log Management

Both scripts create log files. To prevent unbounded growth:

### Rotate Logs Daily

Create `/etc/logrotate.d/monitoring-scripts`:
```
/var/log/system_health_*.log /var/log/app_health_*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
}
```

---

## Integration with Alerting Systems

### Send Alerts to Slack

Modify the `send_alert()` function in `system_health_monitor.sh`:
```bash
send_alert() {
    local message="$1"
    # Send to Slack
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"ALERT: ${message}\"}" \
        https://hooks.slack.com/services/YOUR/WEBHOOK/URL
}
```

### Send Email Alerts

Use `mail` command:
```bash
send_alert() {
    local message="$1"
    echo "$message" | mail -s "System Health Alert" admin@example.com
}
```

---

## Testing

### Test System Health Monitor
```bash
# Run once
./system_health_monitor.sh

# Verify logs were created
ls -la logs/
```

### Test Application Health Checker
```bash
# Test with known UP site
./app_health_checker.sh https://www.google.com

# Test with known DOWN scenario
./app_health_checker.sh https://httpstat.us/500

# Test with multiple URLs
./app_health_checker.sh http://34.93.177.251 https://github.com
```

---

## Troubleshooting

### Permission Denied for /var/log

If you get permission errors writing to `/var/log`:
- The scripts automatically fallback to `./logs/` directory
- Or run with sudo: `sudo ./system_health_monitor.sh`

### CPU Usage Shows >100%

On multi-core systems, CPU usage is cumulative across all cores. This is expected behavior. To get per-core average, modify the CPU calculation in the script.

### Application Health Checker Returns "000"

This usually indicates:
- Connection timeout
- DNS resolution failure
- Network unreachability
- SSL/TLS certificate issues

Check network connectivity and increase timeout with `-t` flag.

---

## License

These scripts are part of the Wisecow application deployment project.
