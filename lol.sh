#!/bin/bash

# --- Default Configuration ---
CPU_IDLE_THRESHOLD=95   # Shutdown if CPU idle is MORE than 95% (i.e., usage < 5%)
CHECK_INTERVAL=30       # Check CPU usage every 30 seconds
REQUIRED_DURATION=600   # Shutdown if condition met for 600 seconds (10 minutes)
ACTUALLY_SHUTDOWN=false # By default, don't actually shutdown
# --- End Default Configuration ---

# --- Style Functions ---
# Color definitions
PRIMARY_COLOR=212  # Pink
SECONDARY_COLOR=99 # Purple
ACCENT_COLOR=214   # Orange/Yellow
ERROR_COLOR=196    # Red

# Style helper functions
style_title() {
    gum style --bold --foreground=$PRIMARY_COLOR --border=normal --border-foreground=$PRIMARY_COLOR --padding="1 2" -- "$1"
}

style_description() {
    gum style --foreground=$SECONDARY_COLOR -- "$1"
}

style_header() {
    gum style --bold -- "$1"
}

style_option() {
    gum style --foreground=$ACCENT_COLOR -- "$1"
}

style_error() {
    gum style --foreground=$ERROR_COLOR -- "$1"
}

style_warning() {
    gum style --foreground=$ERROR_COLOR -- "$1"
}

style_info() {
    gum style -- "$1"
}

style_value() {
    gum style --foreground="$2" -- "$1"
}
# --- End Style Functions ---

# set -ex

# --- Parse Command Line Arguments ---
print_usage() {
    echo ""
    # Title
    style_title 'Love Me Or Leave Me'
    echo ""
    # Description
    style_description 'Monitors CPU idle and shuts down the system when idle conditions are met.'
    echo ""
    # Options header
    style_header 'OPTIONS:'
    echo ""
    # Option rows
    style_option '-i, --idle-percent  PERCENT   CPU idle threshold percentage (default: 95)'
    style_option '-t, --idle-time  SECONDS      Required idle duration in seconds (default: 600)'
    style_option '-c, --check-interval SECONDS  Interval between checks in seconds (default: 30)'
    style_option '-s, --shutdown                Actually perform shutdown when threshold reached'
    style_option '-h, --help                    Display this help message and exit'
    echo ""
    exit 0
}

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
    -s | --shutdown)
        ACTUALLY_SHUTDOWN=true
        shift
        ;;
    -h | --help)
        print_usage
        ;;
    *)
        echo ""
        style_error "Error: Unknown option: $1"
        print_usage
        ;;
    esac
done

# Display warning if in simulation mode
if [ "$ACTUALLY_SHUTDOWN" = false ]; then
    echo ""
    style_warning "WARNING: Running in simulation mode. Use --shutdown flag to enable actual shutdown."
    echo ""
fi

# Check for vmstat availability
if ! command -v vmstat &>/dev/null; then
    echo ""
    style_error "Error: vmstat command not found."
    exit 1
fi

# Validate inputs
if ! [[ "$CPU_IDLE_THRESHOLD" =~ ^[0-9]+$ ]] || [ "$CPU_IDLE_THRESHOLD" -lt 0 ] || [ "$CPU_IDLE_THRESHOLD" -gt 100 ]; then
    echo ""
    style_error "Error: Idle threshold must be a number between 0 and 100"
    echo ""
    exit 1
fi

if ! [[ "$REQUIRED_DURATION" =~ ^[0-9]+$ ]] || [ "$REQUIRED_DURATION" -le 0 ]; then
    echo ""
    style_error "Error: Idle time must be a positive number"
    echo ""
    exit 1
fi

if ! [[ "$CHECK_INTERVAL" =~ ^[0-9]+$ ]] || [ "$CHECK_INTERVAL" -le 0 ]; then
    echo ""
    style_error "Error: Check interval must be a positive number"
    echo ""
    exit 1
fi

idle_counter=0
REQUIRED_CHECKS=$((REQUIRED_DURATION / CHECK_INTERVAL))

# Title box
style_title "Monitoring CPU usage"
echo ""

# Mode message
MODE_MSG=$(if [ "$ACTUALLY_SHUTDOWN" = true ]; then echo "with actual shutdown"; else echo "in simulation mode"; fi)
style_info "Will run ${MODE_MSG} if idle > ${CPU_IDLE_THRESHOLD}% for ${REQUIRED_DURATION} seconds."
echo ""

while true; do
    # Get current CPU idle percentage. Using vmstat here.
    # vmstat 1 2 runs vmstat, waits 1 sec, runs again, takes 2nd line, gets 15th field (%idle)
    current_idle=$(vmstat 1 2 | tail -n 1 | awk '{print $15}')

    # Check if integer value
    if ! [[ "$current_idle" =~ ^[0-9]+$ ]]; then
        echo ""
        style_error "Error reading CPU idle value. Skipping check."
        idle_counter=0 # Reset counter on error
        sleep "$CHECK_INTERVAL"
        continue
    fi

    PROGRESS=$((idle_counter * 100 / REQUIRED_CHECKS))
    COLOR=$(if [ "$PROGRESS" -lt 33 ]; then echo "99"; elif [ "$PROGRESS" -lt 66 ]; then echo "220"; else echo "196"; fi)

    # Status message
    echo -n "CPU Idle: "
    style_value "${current_idle}%" "$COLOR"
    echo -n " | Threshold: >"
    style_option "${CPU_IDLE_THRESHOLD}%"
    echo -n " | Progress: "
    style_value "${idle_counter}/${REQUIRED_CHECKS}" "$COLOR"
    echo ""

    # Wait with spinner if there is progress
    if [ "$idle_counter" -gt 0 ]; then
        TIME_LEFT=$((REQUIRED_DURATION - idle_counter * CHECK_INTERVAL))
        gum spin --spinner dot --title "Time until action: ${TIME_LEFT}s" sleep 1
    fi

    if [ "$current_idle" -gt "$CPU_IDLE_THRESHOLD" ]; then
        # Increment the counter if idle threshold is met
        idle_counter=$((idle_counter + 1))
    else
        # Reset the counter if usage goes above threshold
        idle_counter=0
    fi

    if [ "$idle_counter" -ge "$REQUIRED_CHECKS" ]; then
        echo ""
        style_warning "CPU has been idle for ${REQUIRED_DURATION} seconds."
        echo ""

        if [ "$ACTUALLY_SHUTDOWN" = true ]; then
            if gum confirm "Are you sure you want to shut down?"; then
                echo ""
                style_warning "Initiating shutdown..."
                # Use the appropriate shutdown command for your system
                if command -v systemctl &>/dev/null; then
                    sudo systemctl poweroff
                else
                    sudo shutdown -h now
                fi
            else
                echo ""
                style_info "Shutdown aborted. Exiting."
                exit 0
            fi
        else
            echo ""
            style_info "Simulation mode: Would shut down now if --shutdown flag was used."
            echo ""

            if gum confirm "Exit?"; then
                exit 0
            else
                # Reset counter to avoid immediate re-triggering
                idle_counter=$((REQUIRED_CHECKS / 2))
            fi
        fi
    fi

    # Wait for the next check
    sleep "$CHECK_INTERVAL"
done
