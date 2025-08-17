#!/bin/bash

# Funkcija za namestitev Svxlink
install_svxlink() {
    echo ""
    echo "=== Posodabljam repozitorije in nameščam potrebne knjižnice ==="
    apt update
    apt upgrade -y
    apt install -y g++ cmake make libsigc++-2.0-dev libgsm1-dev libpopt-dev \
        tcl-dev libgcrypt20-dev libspeex-dev libasound2-dev libopus-dev \
        librtlsdr-dev doxygen groff alsa-utils vorbis-tools curl \
        libcurl4-openssl-dev git rtl-sdr libjsoncpp-dev libgpiod-dev \
        libssl-dev ladspa-sdk

    echo ""
    echo "=== Dodajam uporabnika svxlink ==="
    id -u svxlink &>/dev/null || useradd -rG audio,plugdev,dialout svxlink
    groups svxlink

    echo ""
    echo "=== Kloniram repozitorij Svxlink ==="
    cd /usr/src || exit 1
    if [ ! -d "svxlink" ]; then
        git clone http://github.com/sm0svx/svxlink.git
    fi
    cd svxlink || exit 1
    git fetch
    git checkout 25.05.1

    echo ""
    echo "=== Gradim paket ==="
    mkdir -p src/build
    cd src/build || exit 1
    cmake -DUSE_QT=OFF -DCMAKE_INSTALL_PREFIX=/usr \
        -DSYSCONF_INSTALL_DIR=/etc -DLOCAL_STATE_DIR=/var \
        -DWITH_SYSTEMD=ON -DCPACK_GENERATOR=DEB ..
    make -j"$(nproc)" all doc package

    echo ""
    echo "=== Nameščam paket ==="
    dpkg -i svxlink-25.05.1-Linux.deb

    echo ""
    echo "=== Nalagam zvoke ==="
    cd /usr/share/svxlink/sounds/ || exit 1
    curl -LO https://github.com/sm0svx/svxlink-sounds-en_US-heather/releases/download/24.02/svxlink-sounds-en_US-heather-16k-24.02.tar.bz2
    echo ""
    tar xvjf svxlink-sounds-en_US-heather-16k-24.02.tar.bz2
    ln -sfn en_US-heather-16k en_US
}

update_svxlink() {
    TMP_SCRIPT="/tmp/update_svxlink.sh"
    URL="https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/update_svxlink.sh"

    echo ""
    echo "=== Nalagam PMR.SI datoteke ==="

    # Prenos skripte v /tmp
    wget -q -O "$TMP_SCRIPT" "$URL"
    if [ $? -ne 0 ]; then
        echo "❌ Napaka pri prenosu skripte!"
        return 1
    fi

    # Nastavimo dovoljenja za izvajanje
    chmod +x "$TMP_SCRIPT"

    # Izvedemo skripto
    bash "$TMP_SCRIPT"

    systemctl restart svxlink

    # Po izvedbi
    echo -e "✅ Posodobitev Svxlink zaključena!\n"
}


# Funkcija za odstranitev Svxlink
remove_svxlink() {
    echo "=== Ustavljam storitev ==="
    systemctl stop svxlink 2>/dev/null

    echo "=== Odstranjujem paket in knjižnice ==="
    apt purge -y svxlink* g++ cmake make libsigc++-2.0-dev libgsm1-dev libpopt-dev \
        tcl-dev libgcrypt20-dev libspeex-dev libasound2-dev libopus-dev \
        librtlsdr-dev doxygen groff alsa-utils vorbis-tools curl \
        libcurl4-openssl-dev git rtl-sdr libjsoncpp-dev libgpiod-dev \
        libssl-dev ladspa-sdk
    apt autoremove -y

    echo "=== Brisem uporabnika svxlink ==="
    deluser --remove-home svxlink 2>/dev/null

    echo "=== Brisem svxlink healthcheck ==="
    systemctl disable svxlink_healthcheck.service 2>/dev/null
    rm -f /etc/systemd/system/svxlink_healthcheck.service
    rm -f /usr/local/bin/svxlink_healthcheck.sh
    systemctl daemon-reload

    echo "=== Brisem mape ==="
    rm -rf /etc/svxlink /usr/share/svxlink /var/log/svxlink /usr/src/svxlink

    echo -e "✅ Svxlink in vse povezane datoteke odstranjene!\n"
}

# Funkcija za healthcheck
install_healthcheck() {
    echo "=== Nameščam healthcheck skripto ==="

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

    echo -e "✅ Healthcheck nameščen in zagnan!\n"
}

# AIOC konfiguracija (neinteraktivna)
install_aioc_settings() {
    echo "🔧 Začenjam AIOC konfiguracijo..."
    wget -O /tmp/AIOC_settings.bash https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/AIOC_settings.sh
    chmod +x /tmp/AIOC_settings.bash
    if bash /tmp/AIOC_settings.bash; then
        echo -e "✅ AIOC konfiguracija uspešno izvedena.\n"
    else
        echo ""
        echo -e "❌ Pri AIOC konfiguraciji je prišlo do napake.\n"
    fi
}

# FRN konfiguracija (interaktivna)
install_frn_settings() {
    echo "🔧 Začenjam FRN konfiguracijo (interaktivno)..."
    wget -O /tmp/FRN_settings.bash https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/FRN_settings.sh
    chmod +x /tmp/FRN_settings.bash
    bash /tmp/FRN_settings.bash
}

# Namesti vse
full_install() {
    echo "🚀 Začenjam popolno namestitev Svxlink programa na PMR.SI standard."

    install_svxlink
    update_svxlink
    install_healthcheck
    echo ""
    read -p "⚠️ Pred nadaljevanjem avtomatske AIOC konfiguracije se prepričajte, da je AIOC naprava priključena v USB vhod računalnika in svetijo zelene lučke. Pritisnite Enter za nadaljevanje..." 
    install_aioc_settings
    install_frn_settings

    echo -e "✅ Popolna namestitev končana!\n"
}

# Glavni meni
OPTION=$(whiptail --title "SVXLINK - PMR.SI Setup" --menu "Izberi možnost:" 15 70 4 \
"1" "Namesti vse (2,3,4 + AIOC + FRN)" \
"2" "Namesti Svxlink" \
"3" "Posodobi Svxlink na PMR.SI standard" \
"4" "Namesti HealthCheck za Svxlink" \
"5" "Odstrani Svxlink in knjižnice" 3>&1 1>&2 2>&3)

case $OPTION in
    1) full_install ;;
    2) install_svxlink ;;
    3) update_svxlink ;;
    4) install_healthcheck ;;
    5) remove_svxlink ;;
    *) echo "Preklicano." ;;
esac

