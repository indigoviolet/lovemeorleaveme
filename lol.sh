#!/bin/bash

# --- Default Configuration ---
CPU_IDLE_THRESHOLD=95 # Shutdown if CPU idle is MORE than 95% (i.e., usage < 5%)
CHECK_INTERVAL=30     # Check CPU usage every 30 seconds
REQUIRED_DURATION=600 # Shutdown if condition met for 600 seconds (10 minutes)
# --- End Default Configuration ---

# --- Parse Command Line Arguments ---
print_usage() {
    echo "Usage: lovemeorleaveme [OPTIONS]"
    echo "Monitors CPU idle and shuts down the system if idle conditions are met."
    echo ""
    echo "Options:"
    echo "  -i, --idle-percent PERCENT   CPU idle threshold percentage (default: 95)"
    echo "  -t, --idle-time SECONDS      Required idle duration in seconds (default: 600)"
    echo "  -c, --check-interval SECONDS Interval between checks in seconds (default: 30)"
    echo "  -h, --help                   Display this help message and exit"
    exit 0
}

# Require at least one argument
if [ $# -eq 0 ]; then
    echo "Error: No arguments provided"
    print_usage
    exit 1
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
    -i | --idle-percent)
        CPU_IDLE_THRESHOLD="$2"
        shift 2
        ;;
    -t | --idle-time)
        REQUIRED_DURATION="$2"
        shift 2
        ;;
    -c | --check-interval)
        CHECK_INTERVAL="$2"
        shift 2
        ;;
    -h | --help)
        print_usage
        ;;
    *)
        echo "Unknown option: $1"
        print_usage
        ;;
    esac
done

# Check for vmstat availability
if ! command -v vmstat &>/dev/null; then
    echo "Error: vmstat command not found."
    exit 1
fi

# Validate inputs
if ! [[ "$CPU_IDLE_THRESHOLD" =~ ^[0-9]+$ ]] || [ "$CPU_IDLE_THRESHOLD" -lt 0 ] || [ "$CPU_IDLE_THRESHOLD" -gt 100 ]; then
    echo "Error: Idle threshold must be a number between 0 and 100"
    exit 1
fi

if ! [[ "$REQUIRED_DURATION" =~ ^[0-9]+$ ]] || [ "$REQUIRED_DURATION" -le 0 ]; then
    echo "Error: Idle time must be a positive number"
    exit 1
fi

if ! [[ "$CHECK_INTERVAL" =~ ^[0-9]+$ ]] || [ "$CHECK_INTERVAL" -le 0 ]; then
    echo "Error: Check interval must be a positive number"
    exit 1
fi

idle_counter=0
REQUIRED_CHECKS=$((REQUIRED_DURATION / CHECK_INTERVAL))

echo "Monitoring CPU usage. Shutdown if idle > ${CPU_IDLE_THRESHOLD}% for ${REQUIRED_DURATION} seconds."

while true; do
    # Get current CPU idle percentage. Using vmstat here.
    # vmstat 1 2 runs vmstat, waits 1 sec, runs again, takes 2nd line, gets 15th field (%idle)
    current_idle=$(vmstat 1 2 | tail -n 1 | awk '{print $15}')

    # Check if integer value
    if ! [[ "$current_idle" =~ ^[0-9]+$ ]]; then
        echo "Error reading CPU idle value. Skipping check."
        idle_counter=0 # Reset counter on error
        sleep "$CHECK_INTERVAL"
        continue
    fi

    echo "Current CPU Idle: ${current_idle}% (Threshold: >${CPU_IDLE_THRESHOLD}%) | Consecutive checks: ${idle_counter}/${REQUIRED_CHECKS}"

    if [ "$current_idle" -gt "$CPU_IDLE_THRESHOLD" ]; then
        # Increment the counter if idle threshold is met
        idle_counter=$((idle_counter + 1))
    else
        # Reset the counter if usage goes above threshold
        idle_counter=0
    fi

    if [ "$idle_counter" -ge "$REQUIRED_CHECKS" ]; then
        echo "CPU has been idle for ${REQUIRED_DURATION} seconds. Initiating shutdown."
        # Use the appropriate shutdown command for your system
        # Ensure this script runs with root privileges or use sudo
        sudo systemctl poweroff
        # or sudo shutdown -h now
        exit 0 # Exit script after initiating shutdown
    fi

    # Wait for the next check
    sleep "$CHECK_INTERVAL"
done
