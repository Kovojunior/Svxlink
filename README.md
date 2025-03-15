# Svxlink
**PMR.si fork of Svxlink**

Svxlink je na voljo v uradnih **Debian** repozitorijih, vendar je tamkajšnja različica zastarela.  
Za najnovejšo verzijo je potreben **direktni build** preko terminala.  

Skripta za namestitev je izposojena in je last **Danila S58DB**.  
Svxlink se pogosto uporablja za **EchoLink**.

## 🔧 Namestitev najnovejše različice
Za namestitev uporabi naslednje ukaze:
```bash
git clone https://github.com/s58DB/svxlink_install_wizard.git
cd svxlink_install_wizard
sudo chmod +x svxlink_install_wizard.sh
sudo ./svxlink_install_wizard.sh
```

Za posodobitev pomembnih konfiguracijskih datotek Svxlinka na osnovo, ki jo uporabljamo v PMR.si, uporabi sledečo skripto update_svxlink.sh.

Repozitorij vsebuje tudi nekaj zvočnih datotek.
Sledi naslednjim korakom za posodobitev:
```bash
cd /tmp
wget -O update_svxlink.sh https://raw.githubusercontent.com/Kovojunior/Svxlink/main/update_svxlink.sh
sudo chmod +x update_svxlink.sh
sudo bash ./update_svxlink.sh
```
