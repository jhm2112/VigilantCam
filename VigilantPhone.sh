# Dependencies check 
pkg install jq bc termux-api -y

# Configuration
SENSOR="accelerometer"
SENSITIVITY=0.3  # Adjust for sensitivity
COOLDOWN=4  # Cooldown period in seconds
LAST_CAPTURE_TIME=0

# Function to capture a photo
take_photo() {
    local CAPTURE_PATH="/storage/emulated/0/DCIM/Camera/motion_capture_$(date +%Y%m%d_%H%M%S).jpg"
    echo "Taking pic"
    
    if termux-camera-photo -c 1 "$CAPTURE_PATH"; then
        echo "Success, pic at: $CAPTURE_PATH"
    else
        echo "Failure, no pic"
    fi
    
    LAST_CAPTURE_TIME=$(date +%s)
}

#  Motion detection loop
termux-sensor -s "$SENSOR" | while read -r line; do
    # Check if the output contains values
    if [[ -n "$line" && "$line" =~ \"values\" ]]; then
        VALUES=$(echo "$line" | jq -r '.["'$SENSOR'"].values // empty')

        if [ -n "$VALUES" ]; then
            X=$(echo "$VALUES" | jq -r '.[0] // empty')
            Y=$(echo "$VALUES" | jq -r '.[1] // empty')
            Z=$(echo "$VALUES" | jq -r '.[2] // empty')

            # Ensure valid numbers
            if [[ "$X" =~ ^-?[0-9.]+$ && "$Y" =~ ^-?[0-9.]+$ && "$Z" =~ ^-?[0-9.]+$ ]]; then
                MAGNITUDE=$(awk "BEGIN {print sqrt(($X)^2 + ($Y)^2 + ($Z)^2)}")

                # Get current time for cooldown
                CURRENT_TIME=$(date +%s)
                TIME_DIFF=$((CURRENT_TIME - LAST_CAPTURE_TIME))

                if (( $(echo "$MAGNITUDE > $SENSITIVITY" | bc -l) )) && [ "$TIME_DIFF" -ge "$COOLDOWN" ]; then
                    take_photo
                fi
            fi
        fi
    fi
done
