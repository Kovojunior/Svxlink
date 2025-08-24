## 1. SVXLINK INSTALLER SCRIPT FOR LINUX SBCs

`installer.sh` is a Bash script designed to automate the installation of **SvxLink** on single-board computers (SBCs) such as Raspberry Pi and Orange Pi. It ensures all necessary dependencies, libraries, and configurations are applied for smooth operation.
Currently this script **only** (officially) supports `RPi4B` devices.

### 1.1 Components
The script is built using **Bash** and standard Linux utilities like **apt**, **git**, **cmake**, **make**, and **curl**. It also uses **whiptail** for interactive dialogs and **systemctl** to manage the SvxLink service. No additional external libraries are required.

### 1.2 Functionality
1. **Licence acceptance:**
The script first downloads a licence file from a GitHub repository and displays it using a whiptail textbox. The user must accept the licence to proceed. If declined, the installer exits with a message.

2. **Dependency installation:**
The script updates system repositories and installs essential packages including:
    - Compiler tools: **g++**, **make**, **cmake**
    - Audio and radio libraries: **libsigc++-2.0-dev**, **libgsm1-dev**, **libasound2-dev**, **libopus-dev**, **librtlsdr-dev**
    - Additional utilities: **doxygen**, **curl**, **git**, **alsa-utils**, **vorbis-tools**

3. **User creation:**
A system user `svxlink` is added with membership in **audio**, **plugdev**, and **dialout** groups. Existing users are left unchanged.

4. **SvxLink source acquisition**
The script clones the SvxLink repository from GitHub into `/usr/src/svxlink`, fetches updates, and checks out a specific release `25.05.1`.

5. **Build and installation:**
SvxLink is compiled using **cmake** and **make**, with options disabling Qt, specifying installation paths, enabling systemd support, and generating a Debian package. The resulting package is installed using **dpkg -i**.

6. **Additional configurations:**
After installation, the script sets up sounds and other runtime configurations required by SvxLink, ensuring the service can run immediately on supported SBCs.

7. **Verification:**
The script provides terminal feedback for each step using **color-coded messages**. Errors or missing dependencies are highlighted to help users troubleshoot installation issues.

### 1.3 Usage
To use the installer, run the following commands in the terminal:
```bash
mkdir -p /tmp/svxlink_install && cd /tmp/svxlink_install
wget -O installer.sh https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/installer.sh
sudo chmod +x installer.sh  
sudo ./installer.sh  
```

The script will prompt for licence acceptance and guide you through installation steps automatically. Once completed, SvxLink will be installed and ready to configure further with modules such as `ModuleFrn` for **FRN network** operation.

### 1.3.1 List of included installers, updaters, configurators or removers:
1. `Full installer`, installs all scripts that PMR.SI community currently uses in the Svxlink environment.

2. `Svxlink installer`, installs only Svxlink. Make sure to visit an official Svxlink page: `https://www.svxlink.org/`.

3. `Svxlink updater`, updates environment files. Look below.

4. `Python healthcheck installer`, installs only the latest version of Python healthcheck script. 

5. `AIOC configurator`, installs only an AIOC configurator. Look below.

6. `FRN settings configurator`, installs only a FRN configurator. Look below.

7. `Wireguard installer`, installs only Wireguard. Due to security reasons, settings cannot be uploaded to github. Contact `info@pmr446.si` for installation.

8. `Bash healthcheck installer (depricated)`, installs an older version of bash healthcheck script. Depricated since 1.9.2025.

9. `Full remover`, removes everything that can be installed with this installer except for Wireguard.


---
<br></br>
---

## 1. FRN Settings Configurator for SvxLink

`FRN_settings.sh` is a Bash script designed to assist users in updating the **ModuleFrn.conf** configuration file for SvxLink, ensuring proper PMR.SI channel settings, user identification, and location information. The script also updates the **svxlink.conf** file with the user's callsign, making SvxLink ready for immediate use with the FRN network.

### 1.1 Components
The script is built using **standard Linux utilities** and **libraries**:
- **Bash** for scripting.  
- `sed` for in-place file modifications.  
- `grep` and `awk` for parsing configuration files.  
- `systemctl` for managing the SvxLink service.  

No external libraries are required beyond default Linux system tools.

### 1.2 Functionality
1. **Configuration file detection:**
The script targets the `ModuleFrn.conf` file located at `/etc/svxlink/svxlink.d/ModuleFrn.conf`. If the file does not exist, the script exits with an error message.

2. **Computer type detection:**
`get_computer_type()` identifies the type of single-board computer (SBC) running the script by reading `/etc/armbian-release`. Supported types include **RPi4**, **RPi3**, **OPi3**, and **OPiZero**. Unknown boards are labeled as `UnknownARM`.

3. **User input and existing value retrieval:**
The function `read_existing` retrieves existing values from the configuration file for keys such as `EMAIL_ADDRESS` and `DYN_PASSWORD`. Users are prompted to confirm or update each value, and defaults are pre-filled with existing settings.

4. **Callsign and user configuration:**
The script reads the current `CALLSIGN_AND_USER` setting, splitting it into the **callsign** and **user** components. The user is prompted to confirm or modify these values. The combined value is stored in `CALLSIGN_AND_USER`.

5. **Frequency and PMR446 channel selection:**
The script parses the existing `BAND_AND_CHANNEL` frequency, maps it to a **PMR446 channel number** (1-16), and allows the user to select a different channel if desired. The new channel is then used to update the `BAND_AND_CHANNEL` value, including the CTCSS sub-tone setting.

6. **Altitude and description:**
The script reads the current `DESCRIPTION` value to extract the **altitude** in meters. Users can modify this value. A new `DESCRIPTION` string is generated, including the PMR channel, computer type, AIOC interface, and altitude in meters above sea level.

7. **City and city part:**
The script retrieves `CITY_CITY_PART` from the configuration, splitting it into **city** and **city part**. Users are prompted to confirm or update these values, and the combined value is stored back in the configuration.

8. **Backup and update:**
Before making changes, the script creates backups of both `ModuleFrn.conf` and `svxlink.conf`. Configuration values updated include `EMAIL_ADDRESS`, `DYN_PASSWORD`, `CALLSIGN_AND_USER`, `BAND_AND_CHANNEL`, `DESCRIPTION`, and `CITY_CITY_PART`. The user's **CALLSIGN** is also updated in `svxlink.conf`.

    **Files affected and updated:**
    - `/etc/svxlink/svxlink.d/ModuleFrn.conf` -> backup: `/etc/svxlink/svxlink.d/ModuleFrn.conf.bak`
    - `/etc/svxlink/svxlink.conf` -> backup: `/etc/svxlink/svxlink.conf.bak`

9. **Verification:**
The script verifies that all updates have been applied correctly in both `ModuleFrn.conf` and `svxlink.conf`. Success and failure messages are displayed using **color-coded feedback**.

### 1.3 Usage
To run the script with root privileges:

```bash
mkdir -p /tmp/svxlink_install && cd /tmp/svxlink_install
wget -O FRN_settings.sh https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/FRN_settings.sh
sudo chmod +x FRN_settings.sh  
sudo ./FRN_settings.sh 
```
Upon execution, the script will prompt the user to confirm or modify settings such as EMAIL_ADDRESS, DYN_PASSWORD, CALLSIGN, USER, PMR446 channel, altitude, and location information. The script then updates configuration files, restarts the SvxLink service, and displays the service status along with the last 8 log entries.

After running the script, `ModuleFrn.conf` contains the updated FRN configuration, and `svxlink.conf` has the correct **CALLSIGN**. Backups of both files are stored as `ModuleFrn.conf.bak` and `svxlink.conf.bak`. The SvxLink service is restarted to apply the new settings, ensuring immediate operation with the FRN network.

### 1.4 User interaction
When the script runs, the user sees prompts and messages in the following order:

1. **Prompt for EMAIL_ADDRESS:**
EMAIL_ADDRESS [<current value>]: 
    - User can press Enter to keep the default or type a new email address.
2. **Prompt for DYN_PASSWORD:**
DYN_PASSWORD [<current value>]: 
    - User can press Enter to keep the default or type a new password.
3. **Prompt for CALLSIGN:**
CALLSIGN [<current callsign>]: 
    - User can press Enter to keep the current callsign or type a new one.
4. **Prompt for USER:**
USER [<current user>]: 
    - User can press Enter to keep the current user or type a new one.
5. **Prompt for PMR446 channel selection (1-16):**
Choose your operating PMR446 channel (1-16) [<current channel number>]: 
    - User can press Enter to keep the current channel or select a new one.
6. **Prompt for altitude:**
Altitude (in meters) [<current altitude>]: 
    - User can press Enter to keep the current value or type a new altitude.
7. **Prompt for CITY:**
CITY [<current city>]: 
    - User can press Enter to keep the current city or type a new one.
8. **Prompt for CITY_PART:**
CITY_PART [<current city part>]: 
    - User can press Enter to keep the current part or type a new one.

Throughout the process, user input is **optional** for all fields; defaults are shown in **square brackets** and used if **Enter** is pressed.


### 1.4.1 List of possible outcomes
- **Failure:** If the configuration file `/etc/svxlink/svxlink.d/ModuleFrn.conf` does not exist, the script exits with an error:
    ```bash
    ❌ Configuration file /etc/svxlink/svxlink.d/ModuleFrn.conf does not exist.
    ```
- **Success:** When all user inputs are accepted (or defaults used), values are updated correctly in `ModuleFrn.conf` and `svxlink.conf`, and backups are created:
    ```bash
    ✅ ModuleFrn.conf successfully updated.
    ✅ svxlink.conf CALLSIGN successfully updated.
    ✅ ModuleFrn configuration has been updated in /etc/svxlink/svxlink.d/ModuleFrn.conf (backup: /etc/svxlink/svxlink.d/ModuleFrn.conf.bak)
    ✅ CALLSIGN updated in /etc/svxlink/svxlink.conf (backup: /etc/svxlink/svxlink.conf.bak)
    ```
- **Failure:** If updates fail due to permissions or other issues:
    ```bash
    ❌ Failed to update ModuleFrn.conf. Check the file manually!
    ❌ Failed to update CALLSIGN in svxlink.conf. Check the file manually!
    ```
- **Verification:** After update, the script displays the content of `ModuleFrn.conf` with all applied changes and restarts the Svxlink service:
    ```bash
    📄 Updated ModuleFrn configuration:
    (all lines from /etc/svxlink/svxlink.d/ModuleFrn.conf highlighted)
    ```
- **Service check:** Svxlink service status is displayed along with last 8 journal entries:
    ```bash
    Svxlink program status after update:
    ● svxlink.service - SvxLink repeater control software
        Loaded: loaded (/usr/lib/systemd/system/svxlink.service; disabled; preset: enabled)
        Active: active (running) since Sun 2025-08-24 12:16:35 CEST; 1s ago
    Invocation: ca5725db9766451f8f39bd5c8d6eeff1
        Docs: man:svxlink(1)
                man:svxlink.conf(5)
        Process: 5762 ExecStartPre=/bin/touch ${LOGFILE} (code=exited, status=0/SUCCESS)
        Process: 5764 ExecStartPre=/bin/chmod 0644 ${LOGFILE} (code=exited, status=0/SUCCESS)
        Process: 5766 ExecStartPre=/bin/mkdir -m0775 -p ${STATEDIR} (code=exited, status=0/SUCCESS)
        Process: 5768 ExecStartPre=/bin/sh -c chown -R ${RUNASUSER}:$(id -gn ${RUNASUSER}) "${STATEDIR}" "${LOGFILE}" (code=exited, status=0/SUCCESS)
    Main PID: 5772 (svxlink)
        Tasks: 1 (limit: 1563)
        Memory: 2.5M (peak: 2.6M)
            CPU: 181ms
        CGroup: /system.slice/svxlink.service
                └─5772 /usr/bin/svxlink --logfile=/var/log/svxlink --config=/etc/svxlink/svxlink.conf --runasuser=svxlink
    Aug 24 01:45:03 RPi4B systemd[1]: Starting svxlink.service - SvxLink repeater control software...
    Aug 24 01:45:03 RPi4B systemd[1]: Started svxlink.service - SvxLink repeater control software.
    Aug 24 12:16:34 RPi4B systemd[1]: Stopping svxlink.service - SvxLink repeater control software...
    Aug 24 12:16:35 RPi4B systemd[1]: svxlink.service: Deactivated successfully.
    Aug 24 12:16:35 RPi4B systemd[1]: Stopped svxlink.service - SvxLink repeater control software.
    Aug 24 12:16:35 RPi4B systemd[1]: svxlink.service: Consumed 16min 12.987s CPU time, 8.8M memory peak.
    Aug 24 12:16:35 RPi4B systemd[1]: Starting svxlink.service - SvxLink repeater control software...
    Aug 24 12:16:35 RPi4B systemd[1]: Started svxlink.service - SvxLink repeater control software.
    ```

---
<br></br>
---

## AUTOMATIC PMR.SI CONFIGURATION UPDATER FOR SVXLINK
`update_svxlink.sh` is a Bash script designed to automate the update of **PMR.SI standard configuration files** and **sound files** for SvxLink. The script ensures that SvxLink is configured with the latest logic, module, and event scripts, as well as custom audio prompts, without manual intervention. Script by itself does not create backups for updates files so use with caution.

### 1.1 Components
The script is built using **standard Linux utilities** and libraries:
- **Bash** for scripting.
- **wget** for downloading files from GitHub.
- Linux file management commands such as `mkdir`, `chmod`, and `systemctl`.

No external libraries or packages beyond default Linux system tools are required.

### 1.2 Functionality
1. **File mapping and target paths:**
The script defines a list of **source URLs** and their corresponding **target paths** on the system using an associative array `files`. This includes configuration scripts (`.tcl` and `.conf`) in `/usr/share/svxlink/events.d` and `/etc/svxlink/svxlink.d`, as well as **custom sound files** in `/usr/share/svxlink/sounds/en_US/Frn`.

2. **Directory preparation:**
The script ensures that the target sound directory (`/usr/share/svxlink/sounds/en_US/Frn`) exists by creating it if necessary with `mkdir -p`.

3. **Download and update:**
For each entry in the `files` array, the script downloads the file from GitHub using `wget` and saves it to the specified target path. Successful updates are confirmed with a green success message, while failed downloads are flagged with a red error message. After downloading, it sets the correct file permissions using `chmod 644`.

4. **Service restart:**
Once all files are updated, the script restarts the `SvxLink` service using `systemctl restart svxlink` to apply the new configuration and audio files.

### 1.3 Usage
To execute the script with root privileges:

```bash
mkdir -p /tmp/svxlink_install && cd /tmp/svxlink_install
wget -O update_svxlink.sh https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/update_svxlink.sh
sudo chmod +x update_svxlink.sh
sudo bash update_svxlink.sh
```
Upon execution, the script will automatically update the PMR.SI configuration and sound files, ensuring that SvxLink runs with the latest standard. All critical operations, such as download status and file permissions, are logged and displayed in the terminal.

### 1.4. List of possible outcomes:
- **Failure:** If any of the files fail to download (e.g., network error, GitHub unavailable), the script exits with an error:
```bash
❌ Error downloading: <file URL>
```
- **Success:** When all files are downloaded and permissions are set correctly, and the Svxlink service is restarted successfully:
```bash
✅ - Successfully updated: /usr/share/svxlink/events.d/Frn.tcl
✅ - Successfully updated: /usr/share/svxlink/events.d/Logic.tcl
✅ - Successfully updated: /usr/share/svxlink/events.d/Module.tcl
✅ - Successfully updated: /etc/svxlink/svxlink.d/ModuleFrn.conf
✅ - Successfully updated: /etc/svxlink/svxlink.d/ModuleParrot.conf
✅ - Successfully updated: /usr/share/svxlink/events.d/SimplexLogic.tcl
✅ - Successfully updated: /etc/svxlink/svxlink.conf
✅ - Successfully updated: /usr/share/svxlink/sounds/en_US/Frn/connection_lost.wav
✅ - Successfully updated: /usr/share/svxlink/sounds/en_US/Frn/connection_restored.wav
✅ - Successfully updated: /usr/share/svxlink/sounds/en_US/Frn/pmrsi_16b.wav
✅ - Svxlink service restarted successfully
```

---
<br></br>
---

## 1. AUTOMATIC AIOC CONFIGURATOR FOR SVXLINK
`AIOC_settings.sh` is a Bash script designed to automatically configure the **AIOC (All-In-One-Cable)** audio interface for use with SvxLink, a software-based amateur radio transceiver. The script simplifies the setup of **playback**, **capture**, and **PTT (Push-To-Talk)** devices, ensuring that the `svxlink.conf` configuration file is correctly updated without manual editing. File is usually stored in `/etc/svxlink`. Currently Svxlink supports multiple connected TRX devices by configuring `Rx[0-9]` and `Tx[0-9]` code blocks. This script is only optimised for use of one connected TRX device!

### 1.1 Components
The script relies on **standard Linux utilities** and **libraries**:
- **Bash** – scripting language to orchestrate the setup.
- **ALSA utilities** (`aplay`, `arecord`) – used to detect connected audio devices.
- `sed` – for in-place modification of the `svxlink.conf` configuration file.
- Linux device interfaces – `/dev/ttyACM*` for detecting PTT hardware.

No external libraries or packages beyond the default Linux system tools are required.

### 1.2 Algorithm - step by step
1. **Device detection:**
the script detects the **first playback device** matching the `All-In-One-Cable` identifier, the **first capture device** matching the same identifier, and the **first available PTT device** under `/dev/ttyACM*`.
2. **Validation:**
if any of the required devices are missing, the script terminates with an error.

3. **Configuration backup:**
creates a backup of the existing `svxlink.conf` configuration file before making changes.

4. **Configuration update:**
the script updates the SvxLink configuration file by setting the playback device `AUDIO_DEV`, the capture device `CAPTURE_DEV` and the PTT device port `PTT_PORT` to match the detected hardware.

5. **User feedback:**
prints a confirmation message with the updated device settings.


### 1.3 Usage
To run the script, execute it with root privileges:
```bash
mkdir -p /tmp/svxlink_install && cd /tmp/svxlink_install
wget -O AIOC_settings.sh https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/AIOC_settings.sh
sudo chmod +x AIOC_settings.sh
sudo bash AIOC_settings.sh
```
After execution, the script will automatically configure `svxlink.conf` with the detected devices, readying SvxLink for immediate use with the AIOC interface. A backup of the previous configuration is stored as `svxlink.conf.bak` in the same directory.

### 1.4 List of possible outcomes
- **Failure:** If no playback, capture, or PTT device is detected, the script exits with an error:
    ```bash
    ❌ Required audio or PTT devices not found.
    ```
- **Success:** When playback card, capture card, and PTT device are detected, and configuration is updated correctly. Device numbers may vary depending on system hardware:
    ```bash
    ✅ Configuration updated successfully:
    [Rx1] AUDIO_DEV=alsa:plughw:1
    [Tx1] AUDIO_DEV=alsa:plughw:1
    [Tx1] PTT_PORT=/dev/ttyACM0
    ```
- **Failure:** If devices were found, but configuration file update failed (e.g., missing write permissions or unusual config format):
    ```
    ❌ Failed to update /etc/svxlink/svxlink.conf! Please check manually.
    ```
---
