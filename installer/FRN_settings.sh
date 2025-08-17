#!/bin/bash

CONF_FILE="/etc/svxlink/svxlink.d/ModuleFrn.conf"

echo "📌 Konfiguracija Svxlink: /etc/svxlink/svxlink.d/ModuleFrn.conf"

get_computer_type() {
    if [ -f /etc/armbian-release ]; then
        # Vzemi model iz armbian-release
        BOARD=$(grep -oP '(?<=BOARD=).*' /etc/armbian-release)
        # Preimenuj v krajšo obliko za opis
        case "$BOARD" in
            "rpi4") echo "RPi4" ;;
            "rpi3") echo "RPi3" ;;
            "orangepione") echo "OPi3" ;;
            "orangepizero") echo "OPiZero" ;;
            *) echo "$BOARD" ;;  # če ni znan, vrne original
        esac
    else
        echo "UnknownARM"
    fi
}

read_existing() {
    local key="$1"
    local default=$(grep -E "^$key=" "$CONF_FILE" | cut -d'=' -f2- | sed 's/^"//;s/"$//')
    read -p "$key [$default]: " input
    if [ -z "$input" ]; then
        echo "$default"
    else
        echo "$input"
    fi
}

# Preveri, ali datoteka obstaja
if [ ! -f "$CONF_FILE" ]; then
    echo "❌ Konfiguracijska datoteka $CONF_FILE ne obstaja."
    exit 1
fi

# Polja (brez NAME)
EMAIL_ADDRESS=$(read_existing "EMAIL_ADDRESS")
DYN_PASSWORD=$(read_existing "DYN_PASSWORD")

# CALLSIGN in USER ločeno
OLD_CALLSIGN=$(grep -E "^CALLSIGN_AND_USER=" "$CONF_FILE" | cut -d'=' -f2- | sed 's/"//g' | cut -d',' -f1 | xargs)
OLD_USER=$(grep -E "^CALLSIGN_AND_USER=" "$CONF_FILE" | cut -d'=' -f2- | sed 's/"//g' | cut -d',' -f2- | xargs)

read -p "CALLSIGN [$OLD_CALLSIGN]: " input
CALLSIGN="${input:-$OLD_CALLSIGN}"
read -p "USER [$OLD_USER]: " input
USER="${input:-$OLD_USER}"
CALLSIGN_AND_USER="$CALLSIGN, $USER"

# Frekvenca za BAND_AND_CHANNEL
OLD_FREQ=$(grep -E "^BAND_AND_CHANNEL=" "$CONF_FILE" | cut -d'=' -f2- | sed 's/"//g' | awk '{print $1}')

case "$OLD_FREQ" in
  "446.00625") OLD_FREQ_NUM=1 ;;
  "446.01875") OLD_FREQ_NUM=2 ;;
  "446.03125") OLD_FREQ_NUM=3 ;;
  "446.04375") OLD_FREQ_NUM=4 ;;
  "446.05625") OLD_FREQ_NUM=5 ;;
  "446.06875") OLD_FREQ_NUM=6 ;;
  "446.08125") OLD_FREQ_NUM=7 ;;
  "446.09375") OLD_FREQ_NUM=8 ;;
  "446.10625") OLD_FREQ_NUM=9 ;;
  "446.11875") OLD_FREQ_NUM=10 ;;
  "446.13125") OLD_FREQ_NUM=11 ;;
  "446.14375") OLD_FREQ_NUM=12 ;;
  "446.15625") OLD_FREQ_NUM=13 ;;
  "446.16875") OLD_FREQ_NUM=14 ;;
  "446.18125") OLD_FREQ_NUM=15 ;;
  "446.19375") OLD_FREQ_NUM=16 ;;
  *) OLD_FREQ_NUM=16 ;;
esac

read -p "Izberi kanal FREQUENCY (1-16) [$OLD_FREQ_NUM]: " input
FREQ_NUM="${input:-$OLD_FREQ_NUM}"

case "$FREQ_NUM" in
  1) FREQ="446.00625" ;;
  2) FREQ="446.01875" ;;
  3) FREQ="446.03125" ;;
  4) FREQ="446.04375" ;;
  5) FREQ="446.05625" ;;
  6) FREQ="446.06875" ;;
  7) FREQ="446.08125" ;;
  8) FREQ="446.09375" ;;
  9) FREQ="446.10625" ;;
  10) FREQ="446.11875" ;;
  11) FREQ="446.13125" ;;
  12) FREQ="446.14375" ;;
  13) FREQ="446.15625" ;;
  14) FREQ="446.16875" ;;
  15) FREQ="446.18125" ;;
  16) FREQ="446.19375" ;;
  *) echo "Neveljavna izbira, uporabljam privzeto 16"; FREQ="446.19375" ;;
esac

BAND_AND_CHANNEL="$FREQ FM CTCSS100.0 (SUB12)"

# Preberi nadmorsko višino
OLD_ALTITUDE=$(grep -E "^DESCRIPTION=" "$CONF_FILE" | grep -oP '\d+(?=m ASL)' || echo "0")
read -p "Nadmorska višina (v metrih) [$OLD_ALTITUDE]: " input
ALTITUDE="${input:-$OLD_ALTITUDE}"

COMPUTER_TYPE=$(get_computer_type)
DESCRIPTION="PMR CH$FREQ_NUM S12, $COMPUTER_TYPE, Svxlink PMR.SI, AIOC, ${ALTITUDE}m ASL."

# CITY in CITY_PART ločeno
OLD_CITY=$(grep -E "^CITY_CITY_PART=" "$CONF_FILE" | cut -d'=' -f2- | sed 's/"//g' | cut -d',' -f1 | xargs)
OLD_CITY_PART=$(grep -E "^CITY_CITY_PART=" "$CONF_FILE" | cut -d'=' -f2- | sed 's/"//g' | cut -d',' -f2- | xargs)

read -p "CITY [$OLD_CITY]: " input
CITY="${input:-$OLD_CITY}"
read -p "CITY_PART [$OLD_CITY_PART]: " input
CITY_PART="${input:-$OLD_CITY_PART}"
CITY_CITY_PART="$CITY, $CITY_PART"

# Naredi backup
cp "$CONF_FILE" "${CONF_FILE}.bak"
cp /etc/svxlink/svxlink.conf /etc/svxlink/svxlink.conf.bak

# Posodobi ModuleFrn.conf
sed -i "s/^EMAIL_ADDRESS=.*/EMAIL_ADDRESS=$EMAIL_ADDRESS/" "$CONF_FILE"
sed -i "s/^DYN_PASSWORD=.*/DYN_PASSWORD=$DYN_PASSWORD/" "$CONF_FILE"
sed -i "s|^CALLSIGN_AND_USER=.*|CALLSIGN_AND_USER=\"$CALLSIGN_AND_USER\"|" "$CONF_FILE"
sed -i "s|^BAND_AND_CHANNEL=.*|BAND_AND_CHANNEL=\"$BAND_AND_CHANNEL\"|" "$CONF_FILE"
sed -i "s|^DESCRIPTION=.*|DESCRIPTION=\"$DESCRIPTION\"|" "$CONF_FILE"
sed -i "s|^CITY_CITY_PART=.*|CITY_CITY_PART=\"$CITY_CITY_PART\"|" "$CONF_FILE"

# Posodobi glavno svxlink.conf (CALLSIGN=...)
if grep -q "^CALLSIGN=" /etc/svxlink/svxlink.conf; then
    sed -i "s/^CALLSIGN=.*/CALLSIGN=$CALLSIGN/" /etc/svxlink/svxlink.conf
else
    echo "CALLSIGN=$CALLSIGN" >> /etc/svxlink/svxlink.conf
fi

echo "✅ ModuleFrn konfiguracija je posodobljena v $CONF_FILE (backup: ${CONF_FILE}.bak)"
echo "✅ CALLSIGN posodobljen v /etc/svxlink/svxlink.conf (backup: /etc/svxlink/svxlink.conf.bak)"
echo ""
echo "📄 Posodobljena konfiguracija ModuleFrn:"
cat "$CONF_FILE"
