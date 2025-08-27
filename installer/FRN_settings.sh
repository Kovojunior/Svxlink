#!/bin/bash

CONF_FILE="/etc/svxlink/svxlink.d/ModuleFrn.conf"
BACKUP_DIR="/etc/svxlink_backups"

echo -e "\e[1;34m📌 Svxlink configuration file: /etc/svxlink/svxlink.d/ModuleFrn.conf\e[0m"

get_computer_type() {
    if [ -f /etc/armbian-release ]; then
        BOARD=$(grep -oP '(?<=BOARD=).*' /etc/armbian-release)
        case "$BOARD" in
            "rpi4") echo "RPi4" ;;
            "rpi3") echo "RPi3" ;;
            "orangepione") echo "OPi3" ;;
            "orangepizero") echo "OPiZero" ;;
            *) echo "$BOARD" ;;  
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

if [ ! -f "$CONF_FILE" ]; then
    echo ""
    echo -e "\e[1;37;41m❌ Configuration file $CONF_FILE does not exsist.\e[0m\n"    
    exit 1
fi

EMAIL_ADDRESS=$(read_existing "EMAIL_ADDRESS")
DYN_PASSWORD=$(read_existing "DYN_PASSWORD")

OLD_CALLSIGN=$(grep -E "^CALLSIGN_AND_USER=" "$CONF_FILE" | cut -d'=' -f2- | sed 's/"//g' | cut -d',' -f1 | xargs)
OLD_USER=$(grep -E "^CALLSIGN_AND_USER=" "$CONF_FILE" | cut -d'=' -f2- | sed 's/"//g' | cut -d',' -f2- | xargs)

read -p "CALLSIGN [$OLD_CALLSIGN]: " input
CALLSIGN="${input:-$OLD_CALLSIGN}"
read -p "USER [$OLD_USER]: " input
USER="${input:-$OLD_USER}"
CALLSIGN_AND_USER="$CALLSIGN, $USER"

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

read -p "Choose your operating PMR446 channel (1-16) [$OLD_FREQ_NUM]: " input
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
  *) echo -e "\e[1;31mError, using default: 16\e[0m"; FREQ="446.19375" ;;
esac

BAND_AND_CHANNEL="$FREQ FM CTCSS100.0 (SUB12)"

OLD_ALTITUDE=$(grep -E "^DESCRIPTION=" "$CONF_FILE" | grep -oP '\d+(?=m ASL)' || echo "0")
read -p "Altitude (in meters) [$OLD_ALTITUDE]: " input
ALTITUDE="${input:-$OLD_ALTITUDE}"

COMPUTER_TYPE=$(get_computer_type)
DESCRIPTION="PMR CH$FREQ_NUM S12, $COMPUTER_TYPE, Svxlink PMR.SI, AIOC, ${ALTITUDE}m ASL."

OLD_CITY=$(grep -E "^CITY_CITY_PART=" "$CONF_FILE" | cut -d'=' -f2- | sed 's/"//g' | cut -d',' -f1 | xargs)
OLD_CITY_PART=$(grep -E "^CITY_CITY_PART=" "$CONF_FILE" | cut -d'=' -f2- | sed 's/"//g' | cut -d',' -f2- | xargs)

read -p "CITY [$OLD_CITY]: " input
CITY="${input:-$OLD_CITY}"
read -p "CITY_PART [$OLD_CITY_PART]: " input
CITY_PART="${input:-$OLD_CITY_PART}"
CITY_CITY_PART="$CITY, $CITY_PART"

mkdir -p "$BACKUP_DIR"

cp "$CONF_FILE" "${BACKUP_DIR}/ModuleFrn.conf.bak"
cp /etc/svxlink/svxlink.conf "$BACKUP_DIR/svxlink.conf.bak"

sed -i "s/^EMAIL_ADDRESS=.*/EMAIL_ADDRESS=$EMAIL_ADDRESS/" "$CONF_FILE"
sed -i "s/^DYN_PASSWORD=.*/DYN_PASSWORD=$DYN_PASSWORD/" "$CONF_FILE"
sed -i "s|^CALLSIGN_AND_USER=.*|CALLSIGN_AND_USER=\"$CALLSIGN_AND_USER\"|" "$CONF_FILE"
sed -i "s|^BAND_AND_CHANNEL=.*|BAND_AND_CHANNEL=\"$BAND_AND_CHANNEL\"|" "$CONF_FILE"
sed -i "s|^DESCRIPTION=.*|DESCRIPTION=\"$DESCRIPTION\"|" "$CONF_FILE"
sed -i "s|^CITY_CITY_PART=.*|CITY_CITY_PART=\"$CITY_CITY_PART\"|" "$CONF_FILE"

if grep -q "^CALLSIGN=" /etc/svxlink/svxlink.conf; then
    sed -i "s/^CALLSIGN=.*/CALLSIGN=$CALLSIGN/" /etc/svxlink/svxlink.conf
else
    echo "CALLSIGN=$CALLSIGN" >> /etc/svxlink/svxlink.conf
fi

# --- Verify updates in ModuleFrn.conf ---
if grep -q "^EMAIL_ADDRESS=$EMAIL_ADDRESS" "$CONF_FILE" &&
   grep -q "^DYN_PASSWORD=$DYN_PASSWORD" "$CONF_FILE" &&
   grep -q "^CALLSIGN_AND_USER=\"$CALLSIGN_AND_USER\"" "$CONF_FILE" &&
   grep -q "^BAND_AND_CHANNEL=\"$BAND_AND_CHANNEL\"" "$CONF_FILE" &&
   grep -q "^DESCRIPTION=\"$DESCRIPTION\"" "$CONF_FILE" &&
   grep -q "^CITY_CITY_PART=\"$CITY_CITY_PART\"" "$CONF_FILE"; then
    echo -e "\e[1;32m✅ ModuleFrn.conf successfully updated.\e[0m"
else
    echo -e "\e[1;31m❌ Failed to update ModuleFrn.conf. Check the file manually!\e[0m"
fi

# --- Verify updates in svxlink.conf ---
if grep -q "^CALLSIGN=$CALLSIGN" /etc/svxlink/svxlink.conf; then
    echo -e "\e[1;32m✅ svxlink.conf CALLSIGN successfully updated.\e[0m"
else
    echo -e "\e[1;31m❌ Failed to update CALLSIGN in svxlink.conf. Check the file manually!\e[0m"
fi

echo ""
echo -e $'\e[1;32m✅ ModuleFrn configuration has been updated in '"$CONF_FILE"' (backup: '"${CONF_FILE}.bak"')\e[0m'
echo -e $'\e[1;32m✅ CALLSIGN updated in /etc/svxlink/svxlink.conf (backup: /etc/svxlink/svxlink.conf.bak)\e[0m'
echo ""
echo -e "\e[1;34m📄 Updated ModuleFrn configuration:\e[0m"
cat "$CONF_FILE" | while IFS= read -r line; do
    echo -e "\e[1;34m$line\e[0m"
done

sleep 3
systemctl restart svxlink
sleep 1

echo -e "\e[1;34mSvxlink program status after update:\e[0m"
systemctl status svxlink --no-pager --lines=0
journalctl -u svxlink -n 8 --no-pager
echo ""

