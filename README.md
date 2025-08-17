# 📻 SvxLink (pmr.si fork)

**Fork SvxLinka za uporabo na pmr.si projektih**

SvxLink je zmogljiv programski paket za radioamaterske projekte, posebej priljubljen pri uporabi z **EchoLink**, **AllStar** in drugimi VoIP radio sistemi.  
Ker je različica v uradnih Debian repozitorijih pogosto zastarela, ta fork omogoča enostavno namestitev, konfiguracijo in posodobitev na standard, ki ga uporablja pmr.si.

---

## ⚙️ Funkcionalnosti tega forka

- Popolna avtomatizirana namestitev SvxLink iz izvorne kode.  
- Posodobitev SvxLink na pmr.si standard.  
- Avtomatski **HealthCheck**, ki nadzoruje storitev in jo ob morebitnem izpadu ponovno zažene.  
- Podpora za AIOC (avtomatizirana konfiguracija) in FRN (interaktivna konfiguracija).  
- Prenos in namestitev prednastavljenih zvočnih paketov.  
- Enostavna odstranitev SvxLinka in povezanih paketov brez puščanja ostankov.

---

## 📥 Namestitev (build iz izvorne kode)

Za namestitev SvxLink forka na sistem:

```bash
# Ustvari delovno mapo in prenesi skripto
mkdir -p /tmp/svxlink_install && cd /tmp/svxlink_install

# Prenesi Installer
wget -O Installer.sh https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/Installer.sh

# Nastavi dovoljenja in zaženi
sudo chmod +x Installer.sh
sudo bash Installer.sh
```

---

## Navodila in razlaga skripte Installer.sh
Namesti vse – Namesti SvxLink, posodobi na pmr.si standard, namesti HealthCheck, konfigurira AIOC in FRN.
Namesti SvxLink – Samo izvorno kodo in osnovni paket.
Posodobi SvxLink – Posodobi konfiguracijo na pmr.si standard.
Namesti HealthCheck – Samo healthcheck skripto.
Odstrani SvxLink – Odstrani vse skupaj z uporabnikom, paketom in konfiguracijo.

## 🎧 Zvokovne datoteke
Ta skripta prenese in namesti osnovni zvočni paket en_US-heather-16k.
Te zvočne datoteke se uporabljajo za glasovna sporočila in lahko po želji nadomestite ali prilagodite z lastnimi.

## 🔄 Posodobitev konfiguracije
Za posodobitev konfiguracijskih datotek na pmr.si standard, ponovno uporabite Installer:
```bash
cd /tmp/svxlink_install
wget -O Installer.sh https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/Installer.sh
sudo chmod +x Installer.sh
sudo bash Installer.sh
```

## 🛠 HealthCheck
HealthCheck skripta spremlja, ali je SvxLink storitev aktivna, in jo ob morebitnem izpadu ponovno zažene.
Maksimalno število poskusov ponovnega zagona je nastavljeno na 5.
Storitev se avtomatsko zažene ob zagonu sistema.

## 🔧 AIOC in FRN podpora
AIOC konfiguracija – neinteraktivna, avtomatsko nastavi napravo in ustrezne parametre v datoteki svxlink.conf: /etc/svxlink/svxlink.conf
FRN konfiguracija – interaktivna, pomaga pri konfiguraciji datoteke ModuleFrn.conf: /etc/svxlink/svxlink.d/ModuleFrn.conf


## 🧹 Odstranitev SvxLink
Skripta omogoča popolno odstranitev:
Ustavi SvxLink storitev.
Odstrani vse pakete in knjižnice, ki so bili nameščeni.
Izbriše uporabnika svxlink in HealthCheck.
Počisti vse konfiguracijske mape in log datoteke.

## 📬 Več informacij
Več o projektu in aktualnih navodilih najdete na pmr.si.

## 💡 Opombe
Uradna podpora repozitorija je za sistem: Armbian OS bookworm minimal 25.8.1 na mikroračunalniku RaspberryPi 4B.
Pred uporabo AIOC se prepričajte, da je naprava pravilno priključena in pripravljena.
Skripta uporablja sistemske pravice, zato je potreben sudo za namestitev in odstranjevanje.
Skripta podpira avtomatsko gradnjo iz izvorne kode, kar zagotavlja najnovejše izboljšave in popravke.
V kratkem bo skripta dobila podporo tudi mikroračunalniku OrangePi Zero3.
