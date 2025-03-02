#!/bin/bash

# Seznam datotek in njihovih ciljnih poti
declare -A files
files=(
    ["https://github.com/Kovojunior/Svxlink/raw/main/Frn.tcl"]="/usr/share/svxlink/events.d/Frn.tcl"
    ["https://github.com/Kovojunior/Svxlink/raw/main/Logic.tcl"]="/usr/share/svxlink/events.d/Logic.tcl"
    ["https://github.com/Kovojunior/Svxlink/raw/main/Module.tcl"]="/usr/share/svxlink/events.d/Module.tcl"
    ["https://github.com/Kovojunior/Svxlink/raw/main/ModuleFrn.conf"]="/etc/svxlink/svxlink.d/ModuleFrn.conf"
    ["https://github.com/Kovojunior/Svxlink/raw/main/ModuleParrot.conf"]="/etc/svxlink/svxlink.d/ModuleParrot.conf"
    ["https://github.com/Kovojunior/Svxlink/raw/main/SimplexLogic.tcl"]="/usr/share/svxlink/events.d/SimplexLogic.tcl"
    ["https://github.com/Kovojunior/Svxlink/raw/main/svxlink.conf"]="/etc/svxlink/svxlink.conf"
)

# Prenos in zamenjava datotek
for url in "${!files[@]}"; do
    target="${files[$url]}"
    echo "Prenos $url -> $target"
    wget -q -O "$target" "$url"
    if [ $? -eq 0 ]; then
        echo "✅ Uspešno posodobljeno: $target"
    else
        echo "❌ Napaka pri prenosu: $url"
    fi
    
    # Nastavi pravilna dovoljenja
    chmod 644 "$target"
done

# Ponovni zagon storitve
systemctl restart svxlink

echo "✅ Posodobitev končana!"