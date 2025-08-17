#!/bin/bash

# Funkcija za namestitev Svxlink
install_svxlink() {
    echo ""
    echo -e "\e[1;34m=== Posodabljam repozitorije in nameščam potrebne knjižnice ===\e[0m"
    apt update && upgrade -y
    apt update && upgrade -y # TO-DO, včasih javi napako pri prvem zagonu apt update
    apt install -y g++ cmake make libsigc++-2.0-dev libgsm1-dev libpopt-dev \
        tcl-dev libgcrypt20-dev libspeex-dev libasound2-dev libopus-dev \
        librtlsdr-dev doxygen groff alsa-utils vorbis-tools curl \
        libcurl4-openssl-dev git rtl-sdr libjsoncpp-dev libgpiod-dev \
        libssl-dev ladspa-sdk

    echo ""
    echo -e "\e[1;34m=== Dodajam uporabnika svxlink ===\e[0m"
    id -u svxlink &>/dev/null || useradd -rG audio,plugdev,dialout svxlink
    groups svxlink

    echo ""
    echo -e "\e[1;34m=== Kloniram repozitorij Svxlink ===\e[0m"
    cd /usr/src || exit 1
    if [ ! -d "svxlink" ]; then
        git clone http://github.com/sm0svx/svxlink.git
    fi
    cd svxlink || exit 1
    git fetch
    git checkout 25.05.1

    echo ""
    echo -e "\e[1;34m=== Gradim paket ===\e[0m"
    mkdir -p src/build
    cd src/build || exit 1
    cmake -DUSE_QT=OFF -DCMAKE_INSTALL_PREFIX=/usr \
        -DSYSCONF_INSTALL_DIR=/etc -DLOCAL_STATE_DIR=/var \
        -DWITH_SYSTEMD=ON -DCPACK_GENERATOR=DEB ..
    make -j"$(nproc)" all doc package

    echo ""
    echo -e "\e[1;34m=== Nameščam paket ===\e[0m"
    dpkg -i svxlink-25.05.1-Linux.deb

    echo ""
    echo -e "\e[1;34m=== Nalagam zvoke ===\e[0m"
    cd /usr/share/svxlink/sounds/ || exit 1
    curl -LO https://github.com/sm0svx/svxlink-sounds-en_US-heather/releases/download/24.02/svxlink-sounds-en_US-heather-16k-24.02.tar.bz2
    echo ""
    tar xvjf svxlink-sounds-en_US-heather-16k-24.02.tar.bz2
    ln -sfn en_US-heather-16k en_US
}

update_svxlink() {
    MODE=$1   # full_install ali update_svxlink

    # Mapo za varnostne kopije ustvarimo, če ne obstaja
    BACKUP_DIR="/etc/svxlink_backups"

    # Datoteke za morebitno varnostno kopiranje
    declare -A FILES_TO_BACKUP=(
        ["Frn.tcl"]="/usr/share/svxlink/events.d/Frn.tcl"
        ["Logic.tcl"]="/usr/share/svxlink/events.d/Logic.tcl"
        ["Module.tcl"]="/usr/share/svxlink/events.d/Module.tcl"
        ["ModuleFrn.conf"]="/etc/svxlink/svxlink.d/ModuleFrn.conf"
        ["ModuleParrot.conf"]="/etc/svxlink/svxlink.d/ModuleParrot.conf"
        ["SimplexLogic.tcl"]="/usr/share/svxlink/events.d/SimplexLogic.tcl"
        ["svxlink.conf"]="/etc/svxlink/svxlink.conf"
    )

    echo -e "\e[1;34m🔧 Začenja se posodobitev Svxlink konfiguracijskih datotek na standard PMR.SI\n\e[0m" 

    # Odločitve glede varnostnega kopiranja
    if [ "$MODE" == "full_install" ]; then
        BACKUP_CHOICE="n"
    else
        read -p $'\e[1;33m⚠️ Želite izvesti varnostno kopiranje konfiguracijskih datotek pred posodobitvijo? (y/n): \e[0m' BACKUP_CHOICE
    fi

    if [ "$BACKUP_CHOICE" == "y" ]; then
        echo -e "\e[1;34m📦 Ustvarjam varnostne kopije...\e[0m"
        mkdir -p "$BACKUP_DIR"
        for FILE in "${!FILES_TO_BACKUP[@]}"; do
            if [ -f "${FILES_TO_BACKUP[$FILE]}" ]; then
                cp -v "${FILES_TO_BACKUP[$FILE]}" "$BACKUP_DIR/$FILE"
            fi
        done
        echo -e $'\e[1;32m✅ Varnostne kopije so narejene v '"$BACKUP_DIR"$'\e[0m'
    fi

    TMP_SCRIPT="/tmp/update_svxlink.sh"
    URL="https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/update_svxlink.sh"

    echo ""
    echo -e "\e[1;34m=== Nalagam PMR.SI datoteke ===\e[0m"

    # Prenos skripte v /tmp
    wget -q -O "$TMP_SCRIPT" "$URL"
    if [ $? -ne 0 ]; then
    echo -e "\e[1;37;41m❌ Napaka pri prenosu skripte\e[0m\n"
        return 1
    fi

    # Nastavimo dovoljenja za izvajanje
    chmod +x "$TMP_SCRIPT"

    # Izvedemo skripto
    bash "$TMP_SCRIPT"

    # Po izvedbi
    echo -e $'\e[1;32m✅ Posodobitev Svxlink zaključena!\e[0m\n'
}

# Funkcija za odstranitev Svxlink
remove_svxlink() {
    read -p $'\e[1;33m⚠️ Nahajate se v nevarnih vodah. Skripta bo pobrisala vse podatke, odstranila program Svxlink, konfiguratorje in vse knjižnice, ki so z njim povezane (razen WireGuard). Ste prepričani? Pritisnite Enter za nadaljevanje ali CTRL+C za prekinitev...\e[0m' 

    echo ""
    echo -e "\e[1;34m=== Ustavljam storitev Svxlink in HealthCheck ===\e[0m"
    systemctl stop svxlink 2>/dev/null
    systemctl stop svxlink_healthcheck.service 2>/dev/null

    echo ""
    echo -e "\e[1;34m=== Odstranjujem paket in knjižnice povezane s Svxlink ===\e[0m"
    apt purge -y svxlink* g++ cmake make libsigc++-2.0-dev libgsm1-dev libpopt-dev \
        tcl-dev libgcrypt20-dev libspeex-dev libasound2-dev libopus-dev \
        librtlsdr-dev doxygen groff alsa-utils vorbis-tools curl \
        libcurl4-openssl-dev git rtl-sdr libjsoncpp-dev libgpiod-dev \
        libssl-dev ladspa-sdk
    apt autoremove -y

    echo ""
    echo -e "\e[1;34m=== Brisem uporabnika svxlink ===\e[0m"
    deluser --remove-home svxlink 2>/dev/null

    echo ""
    echo -e "\e[1;34m=== Brisem HealthCheck storitev ===\e[0m"
    systemctl disable svxlink_healthcheck.service 2>/dev/null
    rm -f /etc/systemd/system/svxlink_healthcheck.service
    rm -f /usr/local/bin/svxlink_healthcheck.sh
    systemctl daemon-reload

    echo ""
    echo -e "\e[1;34m=== Brisem mape Svxlink ===\e[0m"
    rm -rf /etc/svxlink /usr/share/svxlink /var/log/svxlink /usr/src/svxlink /tmp/AIOC_settings.bash /tmp/FRN_settings.bash

    echo ""
    echo -e $'\e[1;32m✅ Svxlink, konfiguracije in HealthCheck so odstranjeni!\e[0m\n'
}


# Funkcija za healthcheck
install_healthcheck() {
    echo -e "\e[1;34m=== Nameščam healthcheck skripto ===\e[0m"

    cat <<'EOF' > /usr/local/bin/svxlink_healthcheck.sh
#!/bin/bash

SERVICE="svxlink"
MAX_RESTARTS=5
RESTART_COUNT=0

while true; do
    STATUS=$(systemctl is-active $SERVICE)
    if [ "$STATUS" != "active" ]; then
        echo "$(date): Storitev ni aktivna. Poskus ponovnega zagona..." >> /var/log/svxlink_healthcheck.log
        systemctl restart $SERVICE
        sleep 10
        STATUS=$(systemctl is-active $SERVICE)
        if [ "$STATUS" != "active" ]; then
            ((RESTART_COUNT++))
            echo "$(date): Ponovni zagon ni uspel. Poskus št. $RESTART_COUNT" >> /var/log/svxlink_healthcheck.log
        else
            RESTART_COUNT=0
        fi
        if [ $RESTART_COUNT -ge $MAX_RESTARTS ]; then
            echo "$(date): Maksimalno število poskusov doseženo. Prekinjam." >> /var/log/svxlink_healthcheck.log
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
Description=Healthcheck za storitev svxlink
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
    systemctl status svxlink_healthcheck.service   

echo -e $'\e[1;32m✅ Healthcheck nameščen in zagnan!\e[0m\n'
}

# AIOC konfiguracija (neinteraktivna)
install_aioc_settings() {
    echo -e "\e[1;34m🔧 Začenjam AIOC konfiguracijo...\e[0m"
    wget -O /tmp/AIOC_settings.bash https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/AIOC_settings.sh
    chmod +x /tmp/AIOC_settings.bash
    if bash /tmp/AIOC_settings.bash; then
        echo -e $'\e[1;32m✅ AIOC konfiguracija uspešno izvedena.\e[0m\n'
    else
        echo ""
        echo -e $'\e[1;37;41m❌ Pri AIOC konfiguraciji je prišlo do napake.\e[0m\n'
    fi
}

# FRN konfiguracija (interaktivna)
install_frn_settings() {
    echo -e "\e[1;34m🔧 Začenjam FRN konfiguracijo (interaktivno)...\e[0m"
    wget -O /tmp/FRN_settings.bash https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/FRN_settings.sh
    chmod +x /tmp/FRN_settings.bash
    bash /tmp/FRN_settings.bash
}

# Wireguard namestitev brez konfiguracije
install_wireguard() {
    echo -e "\e[1;34m🔧 Začenjam wireguard namestitev...\e[0m"
    apt install wireguard
    echo ""
    echo -e "⚠️ Konfiguracijskih datotek zaradi varnostne grožnje ni mogoče naložiti na splet. Za nastavitev piši na info@pmr446.si\n"
}

# Namesti vse
full_install() {
    read -p $'\e[1;33m🚀 Začenjam popolno namestitev Svxlink programa na PMR.SI standard. Pritisnite Enter za nadaljevanje ali CTRL+C za prekinitev...\e[0m'

    install_svxlink
    update_svxlink "full_install"
    echo ""
    read -p $'\e[1;33m⚠️ Pred nadaljevanjem avtomatske AIOC konfiguracije se prepričajte, da je AIOC naprava priključena v USB vhod računalnika in svetijo zelene lučke. Pritisnite Enter za nadaljevanje...\e[0m\n'    install_aioc_settings
    
    install_frn_settings
    install_healthcheck

    echo -e "\e[1;34mStatus HealthCheck skripte: \e[0m"
    systemctl status svxlink_healthcheck.service
    echo ""
    echo -e "\e[1;34mStatus Svxlink programa: \e[0m"
    systemctl status svxlink
    echo ""

    install_wireguard

    echo ""
    echo -e $'\e[1;32m✅ Popolna namestitev končana!\e[0m\n'
}

# Glavni meni
OPTION=$(whiptail --title "SVXLINK - PMR.SI Setup" --menu "Izberi možnost:" 15 70 4 \
"1" "Namesti vse (2,3,4,5,6,7)" \
"2" "Namesti Svxlink" \
"3" "Posodobi Svxlink konfiguracijske datoteke" \
"4" "Namesti HealthCheck za Svxlink" \
"5" "Namesti AIOC konfigurator za Svxlink" \
"6" "Namesti FRN konfigurator za Svxlink" \
"7" "Namesti WireGuard" \
"8" "Odstrani Svxlink, povezane programe in knjižnice" 3>&1 1>&2 2>&3)

case $OPTION in
    1) full_install ;;
    2) install_svxlink ;;
    3) update_svxlink ;;
    4) install_healthcheck ;;
    5) install_aioc_settings ;;
    6) install_frn_settings ;;
    7) install_wireguard ;;
    8) remove_svxlink ;;
    *) echo "Preklicano." ;;
esac

