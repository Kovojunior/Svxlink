# Svxlink
pmr.si fork of Svxlink

Svxlink ponuja prenos direktno iz Debian repozitorija, a je različica zastarela. 
Za najnovejšo verzijo je potreben direktni build preko terminala. 
Skripta je izposojena in je last Danila S58DB. Svxlink se pogosto uporablja za Echolink.
git clone https://github.com/s58DB/svxlink_install_wizard.git
cd svxlink_install_wizard
sudo chmod +x svxlink_install_wizard.sh
sudo ./svxlink_install_wizard.sh

Za posodobitev pomembnih konfiguracijskih datotek svxlinka na osnovo, ki jo uporabljamo v pmr.si uporabi sledečo skripto update_svxlink.sh. Repozitorij vsebuje tudi nekaj audio datotek. Sledi korakom:
cd /tmp
wget -O update_svxlink.sh https://raw.githubusercontent.com/Kovojunior/Svxlink/main/update_svxlink.sh
sudo chmod +x update_svxlink.sh
sudo bash ./update_svxlink.sh

🚀 

