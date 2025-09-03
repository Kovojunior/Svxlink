#!/bin/bash
# Forced view of a licence file
check_license() {
    LICENCE_URL="https://raw.githubusercontent.com/Kovojunior/Svxlink/main/LICENCE.txt"
    LICENCE_FILE="/tmp/Svxlink_LICENCE.txt"

    echo -e "\e[1;34m=== Downloading licence file ===\e[0m"
    curl -fsSL "$LICENCE_URL" -o "$LICENCE_FILE"

    whiptail --title "Licence" --textbox "$LICENCE_FILE" 50 100

    whiptail --title "Licence" --yesno "Choose yes if you agree with the licence file" 10 50
    if [ $? -ne 0 ]; then
        echo -e "\e[1;31mUser has not accepted the licence file, installer stopped\e[0m"
        exit 1
    fi
}

# Installs svxlink
install_svxlink() {
    echo ""
    echo -e "\e[1;34m=== Updating repositories and configuring necessary libraries ===\e[0m"

    apt update && apt upgrade -y 

    apt install -y g++ cmake make libsigc++-2.0-dev libgsm1-dev libpopt-dev \
        tcl-dev libgcrypt20-dev libspeex-dev libasound2-dev libopus-dev \
        librtlsdr-dev doxygen groff alsa-utils vorbis-tools curl \
        libcurl4-openssl-dev git rtl-sdr libjsoncpp-dev libgpiod-dev \
        libssl-dev ladspa-sdk

    echo ""
    echo -e "\e[1;34m=== Adding user svxlink ===\e[0m"
    id -u svxlink &>/dev/null || useradd -rG audio,plugdev,dialout svxlink
    groups svxlink

    echo ""
    echo -e "\e[1;34m=== Cloning Svxlink repository ===\e[0m"
    cd /usr/src || exit 1
    if [ ! -d "svxlink" ]; then
        git clone http://github.com/sm0svx/svxlink.git
    fi
    cd svxlink || exit 1
    git fetch
    git checkout 25.05.1

    echo ""
    echo -e "\e[1;34m=== Building package ===\e[0m"
    mkdir -p src/build
    cd src/build || exit 1
    cmake -DUSE_QT=OFF -DCMAKE_INSTALL_PREFIX=/usr \
        -DSYSCONF_INSTALL_DIR=/etc -DLOCAL_STATE_DIR=/var \
        -DWITH_SYSTEMD=ON -DCPACK_GENERATOR=DEB ..
    make -j"$(nproc)" all doc package

    echo ""
    echo -e "\e[1;34m=== Installing package ===\e[0m"
    dpkg -i svxlink-25.05.1-Linux.deb

    echo ""
    echo -e "\e[1;34m=== Installing sounds ===\e[0m"
    cd /usr/share/svxlink/sounds/ || exit 1
    curl -LO https://github.com/sm0svx/svxlink-sounds-en_US-heather/releases/download/24.02/svxlink-sounds-en_US-heather-16k-24.02.tar.bz2
    echo ""
    tar xvjf svxlink-sounds-en_US-heather-16k-24.02.tar.bz2
    ln -sfn en_US-heather-16k en_US
}

update_svxlink() {

    echo -e "\e[1;34m=== Installing Hping3 and adding permissions for svxlink ===\e[0m"
    sudo apt install hping3 -y
    echo 'svxlink ALL=(ALL) NOPASSWD: /usr/sbin/hping3' | sudo tee /etc/sudoers.d/hping3
    sudo chmod 440 /etc/sudoers.d/hping3

    MODE=$1   # full_install or update_svxlink

    # Creates backup dir
    BACKUP_DIR="/etc/svxlink_backups"

    # Backup these files
    declare -A FILES_TO_BACKUP=(
        ["Frn.tcl"]="/usr/share/svxlink/events.d/Frn.tcl"
        ["Logic.tcl"]="/usr/share/svxlink/events.d/Logic.tcl"
        ["Module.tcl"]="/usr/share/svxlink/events.d/Module.tcl"
        ["ModuleFrn.conf"]="/etc/svxlink/svxlink.d/ModuleFrn.conf"
        ["ModuleParrot.conf"]="/etc/svxlink/svxlink.d/ModuleParrot.conf"
        ["SimplexLogic.tcl"]="/usr/share/svxlink/events.d/SimplexLogic.tcl"
        ["svxlink.conf"]="/etc/svxlink/svxlink.conf"
    )

    echo ""
    echo -e "\e[1;34m🔧 Svxlink update script starting...\e[0m" 

    # Backup select (y/n)
    if [ "$MODE" == "full_install" ]; then
        BACKUP_CHOICE="n"
    else
        read -p $'\e[1;33m⚠️ Do you want to create backup files before updating? (y/n): \e[0m' BACKUP_CHOICE
    fi

    if [ "$BACKUP_CHOICE" == "y" ]; then
        echo -e "\e[1;34m📦 Creating backup files...\e[0m"
        mkdir -p "$BACKUP_DIR"
        for FILE in "${!FILES_TO_BACKUP[@]}"; do
            if [ -f "${FILES_TO_BACKUP[$FILE]}" ]; then
                cp -v "${FILES_TO_BACKUP[$FILE]}" "$BACKUP_DIR/$FILE"
            fi
        done
        echo -e $'\e[1;32m✅ Backup files created in: '"$BACKUP_DIR"$'\e[0m'
    fi

    TMP_SCRIPT="/tmp/svxlink_install/update_svxlink.sh"
    URL="https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/update_svxlink.sh"

    echo ""
    echo -e "\e[1;34m=== Installing PMR.SI files ===\e[0m"

    wget -q -O "$TMP_SCRIPT" "$URL"
    if [ $? -ne 0 ]; then
    echo -e "\e[1;37;41m❌ Error while downloading script\e[0m\n"
        return 1
    fi

    chmod +x "$TMP_SCRIPT"

    bash "$TMP_SCRIPT"

    echo -e $'\e[1;32m✅ Svxlink update successfully completed!\e[0m\n'
}

# Makes full uninstall
remove_svxlink() {
    read -p $'\e[1;33m⚠️ You are entering dangerous waters. This script will delete all data, remove the Svxlink program, its configurators, and all related libraries (except WireGuard). Are you sure? Press Enter to continue or CTRL+C to abort...\e[0m'

    echo ""
    echo -e "\e[1;34m=== Stopping Svxlink and healthcheck script(s) ===\e[0m"
    systemctl stop svxlink 2>/dev/null
    systemctl stop svxlink_healthcheck.service 2>/dev/null
    systemctl stop svxlink_healthcheck_python.service 2>/dev/null

    echo ""
    echo -e "\e[1;34m=== Removing svxlink packages and libraries ===\e[0m"
    apt purge -y svxlink* g++ cmake make libsigc++-2.0-dev libgsm1-dev libpopt-dev \
        tcl-dev libgcrypt20-dev libspeex-dev libasound2-dev libopus-dev \
        librtlsdr-dev doxygen groff alsa-utils vorbis-tools curl \
        libcurl4-openssl-dev git rtl-sdr libjsoncpp-dev libgpiod-dev \
        libssl-dev ladspa-sdk
    apt autoremove -y

    echo ""
    echo -e "\e[1;34m=== Removing user svxlink ===\e[0m"
    deluser --remove-home svxlink 2>/dev/null

    echo ""
    echo -e "\e[1;34m=== Removing healthcheck script(s) ===\e[0m"
    systemctl disable svxlink_healthcheck.service 2>/dev/null
    systemctl disable svxlink_healthcheck_python.service 2>/dev/null
    rm -f /etc/systemd/system/svxlink_healthcheck.service
    rm -f /etc/systemd/system/svxlink_healthcheck_python.service
    rm -f /usr/local/bin/svxlink_healthcheck.sh
    rm -f /usr/local/bin/svxlink_healthcheck.py
    systemctl daemon-reload

    echo ""
    echo -e "\e[1;34m=== Removing pip watchdog ===\e[0m"
    sudo pip3 uninstall -y watchdog --break-system-packages 2>/dev/null || true

    echo ""
    echo -e "\e[1;34m=== Removing svxlink directories and script files ===\e[0m"
    rm -rf /etc/svxlink /usr/share/svxlink /var/log/svxlink /var/log/svxlink_healthcheck /etc/svxlink_backups /var/log/svxlink_python /usr/src/svxlink /tmp/svxlink_install/AIOC_settings.sh /tmp/svxlink_install/FRN_settings.sh /tmp/svxlink_install/update_svxlink.sh /tmp/svxlink_install/healthcheck.py
    sudo rm -f /etc/sudoers.d/hping3
    sudo apt remove --purge -y hping3
    sudo apt autoremove -y

    echo ""
    echo -e $'\e[1;32m✅ Svxlink, configuration files and healthcheck successfully removed!\e[0m\n'
}

# Installs python healthcheck script
install_healthcheck() {
    echo ""
    echo -e "\e[1;34m=== Installing Python healthcheck script ===\e[0m"

    sudo apt-get install -y python3-watchdog

    if [ -f /lib/systemd/system/svxlink.service ]; then
        echo -e "\e[1;33mChanging svxlink.service: Restart=no...\e[0m"
        sudo sed -i 's/^Restart=.*/Restart=no/' /lib/systemd/system/svxlink.service
        sudo systemctl daemon-reload
    else
        echo -e "\e[1;33mWarning: /lib/systemd/system/svxlink.service does not exist!\e[0m"
    fi

    echo -e "\e[1;33mDownloading healthcheck.py...\e[0m"
    if ! sudo curl -fsSL https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/healthcheck.py -o /usr/local/bin/svxlink_healthcheck.py; then
        echo -e "\e[1;31m❌ Error: Could not download healthcheck.py from GitHub!\e[0m"
        echo -e "\e[1;31mInstallation aborted. Please check your internet connection or GitHub availability.\e[0m"
        return 1
    fi
    sudo chmod +x /usr/local/bin/svxlink_healthcheck.py

    echo ""
    echo -e "\e[1;34m--- Configure Email Settings for Healthcheck ---\e[0m"
    read -rp "Enter sender email (Gmail): " sender
    read -rsp "Enter sender app password: " password
    echo ""
    read -rp "Enter recipient email: " recipient

    sudo sed -i "s|SENDER = .*|SENDER = \"${sender}\"|" /usr/local/bin/svxlink_healthcheck.py
    sudo sed -i "s|PASSWORD = .*|PASSWORD = \"${password}\"|" /usr/local/bin/svxlink_healthcheck.py
    sudo sed -i "s|RECIPIENT = .*|RECIPIENT = \"${recipient}\"|" /usr/local/bin/svxlink_healthcheck.py

    if grep -q "SENDER = \"${sender}\"" /usr/local/bin/svxlink_healthcheck.py &&
    grep -q "PASSWORD = \"${password}\"" /usr/local/bin/svxlink_healthcheck.py &&
    grep -q "RECIPIENT = \"${recipient}\"" /usr/local/bin/svxlink_healthcheck.py; then
        echo -e "\e[1;32m✅ Email settings successfully updated in healthcheck.py\e[0m"
    else
        echo -e "\e[1;31m❌ Failed to update email settings in healthcheck.py! Please check manually.\e[0m"
        return 1
    fi

    echo -e "\e[1;33mBuilding systemd service svxlink_healthcheck_python...\e[0m"
    cat <<'EOF' | sudo tee /etc/systemd/system/svxlink_healthcheck_python.service
[Unit]
Description=Python Healthcheck for svxlink service
After=network.target

[Service]
ExecStart=/usr/bin/python3 /usr/local/bin/svxlink_healthcheck.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable svxlink_healthcheck_python.service
    sudo systemctl start svxlink_healthcheck_python.service
    sleep 1

    echo ""
    echo -e "\e[1;34mStatus of Python script after install:\e[0m"
    systemctl status svxlink_healthcheck_python.service --no-pager --lines=0
    journalctl -u svxlink_healthcheck_python.service -n 5 --no-pager

    sleep 3
    echo ""
    echo -e $'\e[1;32m✅ Python Healthcheck installed and ran!\e[0m\n'
}

# Installs Healthcheck
install_healthcheck_bash() {
    echo ""
    echo -e "\e[1;34m=== Installing bash healthcheck script ===\e[0m"

    cat <<'EOF' > /usr/local/bin/svxlink_healthcheck.sh
#!/bin/bash

SERVICE="svxlink"
MAX_RESTARTS=5
RESTART_COUNT=0

while true; do
    STATUS=$(systemctl is-active $SERVICE)
    if [ "$STATUS" != "active" ]; then
        echo "$(date): Service not active. Trying to restart..." >> /var/log/svxlink_healthcheck.log
        systemctl restart $SERVICE
        sleep 10
        STATUS=$(systemctl is-active $SERVICE)
        if [ "$STATUS" != "active" ]; then
            ((RESTART_COUNT++))
            echo "$(date): Restart failed. Try num. $RESTART_COUNT" >> /var/log/svxlink_healthcheck.log
        else
            RESTART_COUNT=0
        fi
        if [ $RESTART_COUNT -ge $MAX_RESTARTS ]; then
            echo "$(date): Maximum number of failed restarts reached. Stopping..." >> /var/log/svxlink_healthcheck.log
            exit 1
        fi
    else
        RESTART_COUNT=0
    fi
    sleep 15
done
EOF

    chmod +x /usr/local/bin/svxlink_healthcheck.sh

    cat <<'EOF' > /etc/systemd/system/svxlink_healthcheck.service
[Unit]
Description=Bash healthcheck for svxlink
After=network.target

[Service]
ExecStart=/usr/local/bin/svxlink_healthcheck.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable svxlink_healthcheck.service
    systemctl start svxlink_healthcheck.service
    sleep 1 

    echo ""
    echo -e "\e[1;34mStatus of bash healthcheck script after install:\e[0m"
    systemctl status svxlink_healthcheck.service --no-pager --lines=0
    journalctl -u svxlink_healthcheck.service -n 5 --no-pager

    sleep 3
    echo ""
    echo -e $'\e[1;32m✅ Healthcheck installed and run!\e[0m\n'
}

# Installs AIOC configurator
install_aioc_settings() {
    echo ""
    echo -e "\e[1;34m🔧 Starting AIOC reconfiguration...\e[0m"
    wget -O /tmp/svxlink_install/AIOC_settings.sh https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/AIOC_settings.sh
    chmod +x /tmp/svxlink_install/AIOC_settings.sh
    bash /tmp/svxlink_install/AIOC_settings.sh
    status=$?
    if [ $status -eq 0 ]; then
        echo -e "\e[1;32m✅ AIOC reconfiguration successful.\e[0m"
    else
        echo -e "\e[1;37;41m❌ AIOC reconfiguration failed (status=$status).\e[0m"
    fi
}

# Installs FRN configurator
install_frn_settings() {
    echo ""
    echo -e "\e[1;34m🔧 Starting FRN reconfigurator...\e[0m"
    wget -O /tmp/svxlink_install/FRN_settings.sh https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/FRN_settings.sh
    chmod +x /tmp/svxlink_install/FRN_settings.sh
    bash /tmp/svxlink_install/FRN_settings.sh
}

# Installs wireguard
install_wireguard() {
    echo -e "\e[1;34m🔧 Starting wireguard install...\e[0m"
    apt install wireguard
    echo ""
    echo -e "\e[1;37;41m⚠️ Configuration files cannot be uploaded online due to security reasons. For setup, please contact info@pmr.si\n\e[0m"
}

# Full install
full_install() {
    read -p $'\e[1;33m🚀 Starting full install of Svxlink environment on PMR.SI standard. Press Enter to continue or CTRL+C to cancel...\e[0m'

    install_svxlink
    update_svxlink "full_install"

    echo ""
    read -p $'\e[1;33m⚠️ Before proceeding with the automatic AIOC configuration, make sure the AIOC device is connected to the computer\'s USB port and the green LEDs are lit. Press Enter to continue...\e[0m'    
    install_aioc_settings
    
    install_frn_settings
    install_healthcheck

    echo -e "\e[1;34mStatus of HealthCheck script: \e[0m"
    systemctl status svxlink_healthcheck_python.service --no-pager --lines=0
    journalctl -u svxlink_healthcheck_python.service -n 8 --no-pager
    echo ""

    echo -e "\e[1;34mStatus of Svxlink program:\e[0m"
    systemctl status svxlink --no-pager --lines=0
    echo -e "\n\e[1;34mLast 5 lines of the log:\e[0m"
    journalctl -u svxlink -n 8 --no-pager
    echo ""

    install_wireguard

    echo ""
    echo -e $'\e[1;32m✅ Full install completed successfully\e[0m\n'
}

# Menu options
OPTION=$(whiptail --title "SVXLINK - PMR.SI Setup" --menu "What would you like to do today?" 18 70 8 \
"1" "Full install (2,3,4,5,6,7)" \
"2" "Install Svxlink" \
"3" "Update only Svxlink configuration files to PMR.SI standard" \
"4" "Install Python HealthCheck for Svxlink" \
"5" "Install AIOC konfigurator for Svxlink" \
"6" "Install FRN konfigurator for Svxlink" \
"7" "Install WireGuard" \
"8" "Install Bash HealthCheck for Svxlink (depricated) " \
"9" "Remove Svxlink, connected programs and libraries" 3>&1 1>&2 2>&3)

case $OPTION in
    1) check_license; full_install ;;
    2) check_license; install_svxlink ;;
    3) check_license; update_svxlink ;;
    4) check_license; install_healthcheck ;;
    5) check_license; install_aioc_settings ;;
    6) check_license; install_frn_settings ;;
    7) check_license; install_wireguard ;;
    8) check_license; install_healthcheck_bash ;;
    9) check_license; remove_svxlink ;;
    *) echo "Canceled." ;;
esac
