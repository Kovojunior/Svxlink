#!/bin/bash

# List of files and their target paths
declare -A files
files=(
    # Config files
    ["https://raw.githubusercontent.com/Kovojunior/Svxlink/main/pmr_si_configs/Frn.tcl"]="/usr/share/svxlink/events.d/Frn.tcl"
    ["https://raw.githubusercontent.com/Kovojunior/Svxlink/main/pmr_si_configs/Logic.tcl"]="/usr/share/svxlink/events.d/Logic.tcl"
    ["https://raw.githubusercontent.com/Kovojunior/Svxlink/main/pmr_si_configs/Module.tcl"]="/usr/share/svxlink/events.d/Module.tcl"
    ["https://raw.githubusercontent.com/Kovojunior/Svxlink/main/pmr_si_configs/ModuleFrn.conf"]="/etc/svxlink/svxlink.d/ModuleFrn.conf"
    ["https://raw.githubusercontent.com/Kovojunior/Svxlink/main/pmr_si_configs/ModuleParrot.conf"]="/etc/svxlink/svxlink.d/ModuleParrot.conf"
    ["https://raw.githubusercontent.com/Kovojunior/Svxlink/main/pmr_si_configs/SimplexLogic.tcl"]="/usr/share/svxlink/events.d/SimplexLogic.tcl"
    ["https://raw.githubusercontent.com/Kovojunior/Svxlink/main/pmr_si_configs/svxlink.conf"]="/etc/svxlink/svxlink.conf"

    # Existing sounds
    ["https://raw.githubusercontent.com/Kovojunior/Svxlink/main/pmrsi_sounds/connection_lost.wav"]="/usr/share/svxlink/sounds/en_US/Frn/connection_lost.wav"
    ["https://raw.githubusercontent.com/Kovojunior/Svxlink/main/pmrsi_sounds/connection_restored.wav"]="/usr/share/svxlink/sounds/en_US/Frn/connection_restored.wav"
    ["https://raw.githubusercontent.com/Kovojunior/Svxlink/main/pmrsi_sounds/pmrsi_16b.wav"]="/usr/share/svxlink/sounds/en_US/Frn/pmrsi_16b.wav"

    # New sounds
    ["https://raw.githubusercontent.com/Kovojunior/Svxlink/main/pmrsi_sounds/aktivnosti.wav"]="/usr/share/svxlink/sounds/en_US/Frn/aktivnosti.wav"
    ["https://raw.githubusercontent.com/Kovojunior/Svxlink/main/pmrsi_sounds/ankaran.wav"]="/usr/share/svxlink/sounds/en_US/Frn/ankaran.wav"
    ["https://raw.githubusercontent.com/Kovojunior/Svxlink/main/pmrsi_sounds/dravograd.wav"]="/usr/share/svxlink/sounds/en_US/Frn/dravograd.wav"
    ["https://raw.githubusercontent.com/Kovojunior/Svxlink/main/pmrsi_sounds/katarina.wav"]="/usr/share/svxlink/sounds/en_US/Frn/katarina.wav"
    ["https://raw.githubusercontent.com/Kovojunior/Svxlink/main/pmrsi_sounds/kukava.wav"]="/usr/share/svxlink/sounds/en_US/Frn/kukava.wav"
    ["https://raw.githubusercontent.com/Kovojunior/Svxlink/main/pmrsi_sounds/podkum.wav"]="/usr/share/svxlink/sounds/en_US/Frn/podkum.wav"
    ["https://raw.githubusercontent.com/Kovojunior/Svxlink/main/pmrsi_sounds/smarje.wav"]="/usr/share/svxlink/sounds/en_US/Frn/smarje.wav"
    ["https://raw.githubusercontent.com/Kovojunior/Svxlink/main/pmrsi_sounds/zuzemberk.wav"]="/usr/share/svxlink/sounds/en_US/Frn/zuzemberk.wav"
)

# Ensure the sound directory exists
mkdir -p /usr/share/svxlink/sounds/en_US/Frn

# Download and replace files
for url in "${!files[@]}"; do
    target="${files[$url]}"
    echo "Downloading $url -> $target"
    wget -q -O "$target" "$url"
    if [ $? -eq 0 ]; then
        echo -e "\e[1;32m✅ - Successfully updated: $target\e[0m"
    else
        echo -e "\e[1;37;41m❌ - Error downloading: $url\e[0m\n"
    fi
    
    # Set correct permissions
    chmod 644 "$target"
done

# Restart the Svxlink service
systemctl restart svxlink

sleep 3
#echo ""
#echo -e $'\e[1;32m✅ - Update completed!\e[0m\n'
