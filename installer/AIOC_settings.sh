#!/bin/bash

CONFIG_FILE="/etc/svxlink/svxlink.conf"

# Poišči playback in capture kartico
PLAYBACK_CARD=$(aplay -l | grep -i "All-In-One-Cable" | awk -F'[: ]+' '{print $2}' | head -n1)
CAPTURE_CARD=$(arecord -l | grep -i "All-In-One-Cable" | awk -F'[: ]+' '{print $2}' | head -n1)

# Poišči prvi /dev/ttyACM device
PTT_DEVICE=$(ls /dev/ttyACM* 2>/dev/null | head -n1)

# Preveri, če so podatki najdeni
if [ -z "$PLAYBACK_CARD" ] || [ -z "$CAPTURE_CARD" ] || [ -z "$PTT_DEVICE" ]; then
    echo ""
    echo -e "\e[1;37;41m❌ Napaka: potrebni podatki niso najdeni (playback, capture ali PTT).\e[0m\n"
    exit 1
fi

# Naredi backup konfiguracije
cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"

# Posodobi konfiguracijo
sed -i "s|^AUDIO_DEV=.*|AUDIO_DEV=alsa:plughw:$PLAYBACK_CARD|g" "$CONFIG_FILE"
sed -i "s|^CAPTURE_DEV=.*|CAPTURE_DEV=alsa:plughw:$CAPTURE_CARD|g" "$CONFIG_FILE"
sed -i "s|^PTT_PORT=.*|PTT_PORT=$PTT_DEVICE|g" "$CONFIG_FILE"

echo -e $'\e[1;32m✅ Konfiguracija posodobljena:\e[0m'
echo "  AUDIO_DEV=alsa:plughw:$PLAYBACK_CARD"
echo "  CAPTURE_DEV=alsa:plughw:$CAPTURE_CARD"
echo -e "  PTT_PORT=$PTT_DEVICE\n"

systemctl restart svxlink
sleep 1
echo -e "\e[1;34mStanje Svxlink programa po posodobitvi: \e[0m" 
systemctl status svxlink
echo ""
