#!/bin/bash

CONFIG_FILE="/etc/svxlink/svxlink.conf"

# Find playback and capture cards
PLAYBACK_CARD=$(aplay -l | grep -i "All-In-One-Cable" | awk -F'[: ]+' '{print $2}' | head -n1)
CAPTURE_CARD=$(arecord -l | grep -i "All-In-One-Cable" | awk -F'[: ]+' '{print $2}' | head -n1)

# Find the first /dev/ttyACM device
PTT_DEVICE=$(ls /dev/ttyACM* 2>/dev/null | head -n1)

# Check if all required devices were found
if [ -z "$PLAYBACK_CARD" ] || [ -z "$CAPTURE_CARD" ] || [ -z "$PTT_DEVICE" ]; then
    echo -e "\e[1;31m❌ Required audio or PTT devices not found.\e[0m"
    exit 1
fi

# Backup existing configuration
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"

# --- Update ONLY Rx1 and Tx1 sections ---
# Update Rx1 -> CAPTURE_DEV
sed -i "/\[Rx1\]/,/^\[/ s|^AUDIO_DEV=.*|AUDIO_DEV=alsa:plughw:$CAPTURE_CARD|" "$CONFIG_FILE"

# Update Tx1 -> PLAYBACK_DEV
sed -i "/\[Tx1\]/,/^\[/ s|^AUDIO_DEV=.*|AUDIO_DEV=alsa:plughw:$PLAYBACK_CARD|" "$CONFIG_FILE"

# Update Tx1 -> PTT_PORT
sed -i "/\[Tx1\]/,/^\[/ s|^PTT_PORT=.*|PTT_PORT=$PTT_DEVICE|" "$CONFIG_FILE"

# Verify updates
if grep -A3 "^\[Rx1\]" "$CONFIG_FILE" | grep -q "AUDIO_DEV=alsa:plughw:$CAPTURE_CARD" &&
   grep -A5 "^\[Tx1\]" "$CONFIG_FILE" | grep -q "AUDIO_DEV=alsa:plughw:$PLAYBACK_CARD" &&
   grep -A10 "^\[Tx1\]" "$CONFIG_FILE" | grep -q "PTT_PORT=$PTT_DEVICE"; then
    echo -e "\e[1;32m✅ Configuration updated successfully:\e[0m"
    echo -e "\e[1;32m  [Rx1] AUDIO_DEV=alsa:plughw:$CAPTURE_CARD\e[0m"
    echo -e "\e[1;32m  [Tx1] AUDIO_DEV=alsa:plughw:$PLAYBACK_CARD\e[0m"
    echo -e "\e[1;32m  [Tx1] PTT_PORT=$PTT_DEVICE\e[0m\n"
else
    echo -e "\e[1;31m❌ Failed to update $CONFIG_FILE! Please check manually.\e[0m"
    exit 1
fi
