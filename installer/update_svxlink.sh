#!/bin/bash

# Seznam datotek in njihovih ciljnih poti
declare -A files
files=(
    ["https://github.com/Kovojunior/Svxlink/raw/main/pmr_si_configs/Frn.tcl"]="/usr/share/svxlink/events.d/Frn.tcl"
    ["https://github.com/Kovojunior/Svxlink/raw/main/pmr_si_configs/Logic.tcl"]="/usr/share/svxlink/events.d/Logic.tcl"
    ["https://github.com/Kovojunior/Svxlink/raw/main/pmr_si_configs/Module.tcl"]="/usr/share/svxlink/events.d/Module.tcl"
    ["https://github.com/Kovojunior/Svxlink/raw/main/pmr_si_configs/ModuleFrn.conf"]="/etc/svxlink/svxlink.d/ModuleFrn.conf"
    ["https://github.com/Kovojunior/Svxlink/raw/main/pmr_si_configs/ModuleParrot.conf"]="/etc/svxlink/svxlink.d/ModuleParrot.conf"
    ["https://github.com/Kovojunior/Svxlink/raw/main/pmr_si_configs/SimplexLogic.tcl"]="/usr/share/svxlink/events.d/SimplexLogic.tcl"
    ["https://github.com/Kovojunior/Svxlink/raw/main/pmr_si_configs/svxlink.conf"]="/etc/svxlink/svxlink.conf"
    ["https://github.com/Kovojunior/Svxlink/raw/main/pmrsi_sounds/connection_lost.wav"]="/usr/share/svxlink/sounds/en_US/Frn/connection_lost.wav"
    ["https://github.com/Kovojunior/Svxlink/raw/main/pmrsi_sounds/connection_restored.wav"]="/usr/share/svxlink/sounds/en_US/Frn/connection_restored.wav"
    ["https://github.com/Kovojunior/Svxlink/raw/main/pmrsi_sounds/pmrsi_16b.wav"]="/usr/share/svxlink/sounds/en_US/Frn/pmrsi_16b.wav"
)

# Preveri, ali mapa za zvoke obstaja, če ne, jo ustvari
mkdir -p /usr/share/svxlink/sounds/en_US/Frn

# Prenos in zamenjava datotek
for url in "${!files[@]}"; do
    target="${files[$url]}"
    echo "Prenos $url -> $target"
    wget -q -O "$target" "$url"
    if [ $? -eq 0 ]; then
        echo "✅ - Uspešno posodobljeno: $target"
    else
        echo ""
        echo -e "\e[1;37;41m❌ - Napaka pri prenosu: $url\e[0m\n"
    fi
    
    # Nastavi pravilna dovoljenja
    chmod 644 "$target"
done

# Ponovni zagon storitve
systemctl restart svxlink

echo -e $'\e[1;32m✅ - Posodobitev končana!\e[0m\n'