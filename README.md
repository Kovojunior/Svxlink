# Svxlink
pmr.si fork of Svxlink

Svxlink ponuja prenos direktno iz Debian repozitorija, a je različica zastarela. 
Za najnovejšo verzijo je potreben direktni build preko terminala. 
Skripta je izposojena in je last Danila S58DB. Svxlink se pogosto uporablja za Echolink.
git clone https://github.com/s58DB/svxlink_install_wizard.git
cd svxlink_install_wizard
sudo chmode +x svxlink_install_wizard.sh
bash ./svxlink_install_wizard.sh

Za posodobitev pomembnih konfiguracijskih datotek svxlinka na osnovo, ki jo uporabljamo v pmr.si uporabi sledečo skripto update_svxlink.sh
To skripto shrani kot update_svxlink.sh, naredi jo izvedljivo (chmod +x update_svxlink.sh), nato pa jo zaženi kot root (sudo ./update_svxlink.sh). 🚀

