# 📻 SvxLink (pmr.si fork)

**Fork SvxLinka za uporabo na pmr.si projektih**

SvxLink je zmogljiv programski paket za radioamaterske projekte, posebej priljubljen pri uporabi z **EchoLink**.  
Ker je različica v uradnih Debian repozitorijih pogosto zastarela, ta fork omogoča enostavno namestitev in posodobitev najnovejše različice.

---

## 📥 Namestitev (build iz izvorne kode)

Za hitro namestitev se uporabi skripto, ki jo je pripravil Danilo **S58DB**:

```bash
git clone https://github.com/s58DB/svxlink_install_wizard.git
cd svxlink_install_wizard
sudo chmod +x svxlink_install_wizard.sh
sudo ./svxlink_install_wizard.sh
```

## 🔄 Posodobitev konfiguracije

Za posodobitev konfiguracijskih datotek na standard, ki ga uporablja pmr.si, naj se uporabi naslednjo skripto:

```bash
cd /tmp
wget -O update_svxlink.sh https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/update_svxlink.sh
sudo chmod +x update_svxlink.sh
sudo bash ./update_svxlink.sh
```

## 🎧 Zvokovne datoteke

Ta repozitorij vključuje nekaj osnovnih zvočnih datotek, ki jih uporablja SvxLink za glasovna sporočila.
Lahko se jih prosto prilagodi ali zamenja z lastnimi.

## 📬 Več informacij

https://pmr.si