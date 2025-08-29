### 0. AUTHOR'S MESSAGE

I am excited to share this program with the public under the terms of its license! This was my "summer break" project, and as a student at FRI – Faculty of Computer Science and Informatics in Ljubljana, Slovenia, it was a fun and challenging adventure. Developing this healthcheck and its supporting scripts was not just about coding; it was about exploring the possibilities of automating tasks that can be tedious and repetitive, and seeing the results in real time gave me a great sense of accomplishment.

Ham radio is a passion that is very close to my heart, and it is also increasingly difficult today, when phones and digital platforms dominate and can pull potential users away from this wonderful hobby. With these scripts, I hope to make the life of a SvxLink node administrator easier. Tasks that used to require connecting via Putty, checking logs, and manually restarting services can now be automated, giving administrators more time for a coffee break or to enjoy the hobby itself. My goal is that these tools save time, reduce frustration, and allow people to focus on what really matters: experimenting, learning, and connecting with the community.

I also hope that these scripts can help introduce young people to the world of ham radio. There are important frequency bands, like PMR446 or FRS, that do not require a license, where beginners can learn practical skills safely. These bands provide an excellent stepping stone into amateur radio, allowing newcomers to experiment, understand communication principles, and gradually advance to more complex setups. The idea is to provide a hands-on experience that makes learning engaging, safe, and accessible. **Please check with your local authorities for information about Svxlink node legality in your country, especially on licence free bands.**

Finally, I encourage anyone interested in this hobby to explore its borders. My hope is that through these tools and resources, more people will be inspired to explore the rich world of ham radio, enjoy the challenge of managing their own nodes, and appreciate the unique freedoms and learning opportunities that radio frequencies offer. 

It has been a joy to create these scripts, and I share them with the community in the spirit of helping, learning, and growing together in this incredible hobby.

**Note / Disclaimer:**  
The author is not responsible for any damage, data loss, or system errors that may occur while using this software. Use this program at your own risk. This project may contain errors, either in the code or in the documentation. If you encounter any mistakes, I encourage you to report them. The preferred way to report issues is through the GitHub repository. Otherwise, please send a message to info@pmr.si via EMail.

The author does not claim any rights over the SvxLink program itself; this project is an independent tool created to monitor and assist SvxLink, which remains the intellectual property of its original developers.

*Happy Learning!*

---
<br></br>
---

## 1. SVXLINK INSTALLER SCRIPT FOR LINUX SBCs

**IMPORTANT NOTICE: script only officially supports RPi4B and OPi3Zero boards with Debian distributions. I recommend using Debian Lite images. For OS installation [Raspberry Pi Imager](https://www.raspberrypi.com/software/) can be used. Use Raspberry Pi OS Lite (debian) on RPi and Armbian OS minimal on OPi boards. 32-bit boards are not compatible!**

`installer.sh` is a Bash script designed to automate the installation of **SvxLink** on single-board computers (SBCs) such as Raspberry Pi and Orange Pi. It ensures all necessary dependencies, libraries, and configurations are applied for smooth operation.
Currently this script **only** (officially) supports `RPi4B` devices.

### 1.1 Components
The script is built using **Bash** and standard Linux utilities such as `apt`, `git`, `cmake`, `make`, and `curl`:  
- `whiptail` for interactive dialogs.  
- `systemctl` to manage the SvxLink service.  

No additional external libraries are required.  
**Notice:** if the usage of **whiptail** windows is unclear, users are advised to consult tutorials or online guides for guidance on navigating the dialogs. Example: [Wikibooks Whiptail Tutorial](https://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail?utm_source=chatgpt.com).


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

4. **SvxLink source acquisition:**
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
1. `Full installer`, installs all scripts that PMR.SI community currently uses in the Svxlink environment. (List: 2,3,4,5,6,7)
    -  **Initial prompt to start installation:**
        ```bash
        🚀 Starting full install of Svxlink environment on PMR.SI standard.  
        ```
        User must press **Enter** to continue or **CTRL+C** to cancel.

    - **Svxlink installation and update:**  
        `install_svxlink` and `update_svxlink "full_install"` run automatically.  
        User does **not** need to provide input here.

    - **Prompt before AIOC configuration:**
        ```bash
        ⚠️ Before proceeding with the automatic AIOC configuration, make sure the AIOC device is connected to the computer's USB port and the green LEDs are lit.  
        ```
        User must press **Enter** to continue.

    - **Automatic configuration steps:**  
        `install_aioc_settings`, `install_frn_settings`, and `install_healthcheck` run automatically.  
        User does **not** need to interact, unless an error occurs.

    - **HealthCheck service status display:**  
        Current status of `svxlink_healthcheck.service`
        Last 8 journal entries  
        User **observes** the output.

    - **Svxlink program status display:**  
        Current status of `svxlink`
        Last 8 journal entries from the log  
        User **observes** the output.

    - **WireGuard installation:**  
        `install_wireguard` runs automatically.  
        User does **not** need to provide input, but they must either configure the system themselves or contact **info@pmr.si** for assistance.  
            

    - **Completion message:**  
        ```bash
        ✅ Full install completed successfully  
        ```
        Indicates that the full installation process finished without errors.
    <br></br>

2. `Svxlink installer`, installs only Svxlink. Make sure to visit an official Svxlink page: `https://www.svxlink.org/`.
    - **Initial message:**
        ```bash
        === Updating repositories and configuring necessary libraries ===
        ```  
        User sees that the system will update package repositories and install required libraries.  
        No input is required; the script runs `apt update`, `apt upgrade`, and installs dependencies automatically.


    - **Adding the svxlink user:**
        ```bash
        === Adding user svxlink ===  
        ```  
        Script checks if the `svxlink` user exists.  
        If not, it creates the user and adds it to `audio`, `plugdev`, and `dialout` groups.  
        User sees the groups assigned to `svxlink`.  
        No input is required.

    - **Cloning the Svxlink repository:**
        ```bash
        === Cloning Svxlink repository ===  
        ```
        Script changes to `/usr/src`.  
        If the `svxlink` directory does not exist, it clones the repository from GitHub.  
        The script fetches the latest updates and checks out version `25.05.1`.  
        User sees messages from `git clone`, `git fetch`, and `git checkout`.  
        No input is required.

    - **Building the Svxlink package:**
        ```bash
        === Building package ===  
        ```
        Script creates a build directory (`src/build`) and runs `cmake` with configuration options.  
        It compiles the source code using `make -j$(nproc)` and generates documentation and DEB package.  
        User sees compilation output, progress, and any errors.  
        No input is required, but the user can monitor progress for errors.

    - **Installing the package:**
        ```bash
        === Installing package ===  
        ```
        Script installs the generated DEB package with `dpkg -i`.  
        User sees installation messages.  
        No input is required unless `dpkg` reports dependency issues.

    - **Installing sounds:**
        ```bash
        === Installing sounds === 
        ``` 
        Script downloads the `svxlink-sounds-en_US-heather` archive from GitHub using `curl`.  
        The archive is extracted in `/usr/share/svxlink/sounds/` and a symbolic link is created (`en_US` → `en_US-heather-16k`).  
        User sees download progress and extraction messages.  
        No input is required.

    - **Summary:**  
        The entire `install_svxlink()` process is mostly automatic.  
        User **observes** output messages and compilation progress.  
        No interactive input is needed.  
        If errors occur during compilation or installation, the user may need to resolve missing dependencies or permission issues manually.
    <br></br>

3. `Svxlink updater`, updates environment files. See chapter **III (3)**.
   <br></br>

4. `Python healthcheck installer`, installs only the latest version of Python healthcheck script. 
    - **Initial message:**
        ```bash
        === Installing Python healthcheck script ===
        ```
        User sees that the Python healthcheck script will be installed.  
        No input is required at this stage.

    - **Python and pip installation:**
        ```bash
        Forcing python and pip install...
        ```
        The script installs `python3` and `pip3` if not already installed.  
        User observes progress; no input is required.

    - **Watchdog installation:**
        ```bash
        Installing watchdog with --break-system-packages...
        ```
        Installs Python `watchdog` library using pip.  
        User observes progress; no input is required.

    - **Modifying svxlink.service restart behavior:**
        ```bash
        Changing svxlink.service: Restart=no...
        ```
        Script modifies systemd service to prevent automatic restart conflicts.  
        User observes messages; no input required.

    - **Downloading healthcheck.py:**
        ```bash
        Downloading healthcheck.py...
        ```
        Script fetches `healthcheck.py` from GitHub and sets execution permissions.  
        User observes download progress.  
        If download fails, user must check internet connection or GitHub availability.

    - **Configuring email settings for Python healthcheck:**
        ```bash
        --- Configure Email Settings for Healthcheck ---
        Enter sender email (Gmail):
        Enter sender app password:
        Enter recipient email:
        ```
        User **must** input:
        - Sender email address
        - Sender app password
        - Recipient email address

        These values are written into `healthcheck.py`.  
        Script verifies that email settings were correctly applied.
        **Note:** configurator takes inputs one by one, user must press Enter to apply changes after each input. User can generate an APP password for the Gmail account [on this link](https://myaccount.google.com/apppasswords) or follow google instructions.

    - **Creating Python systemd service:**
        ```bash
        Building systemd service svxlink_healthcheck_python...
        ```
        Script creates and enables `/etc/systemd/system/svxlink_healthcheck_python.service`.  
        Service is started automatically.  
        User observes status and last 5 journal entries.

    - **Completion message:**
        ```bash
        ✅ Python Healthcheck installed and ran!
        ```
        Indicates that the Python healthcheck script is installed, configured, and running.

    - **User input summary:**  
        Must provide email credentials for Python healthcheck (sender email, app password, recipient email).  
        All other steps run automatically, but the user observes installation progress, systemd status, and logs.  
        If downloads or installations fail, user may need to troubleshoot connectivity or permissions.
    <br></br>


5. `AIOC configurator`, installs only an AIOC configurator. See chapter **IV (4)**.
    <br></br>

6. `FRN settings configurator`, see chapter **II (2)**
    <br></br>

7. `WireGuard installer`, installs the WireGuard VPN package required for secure connections.  
    - **Initial message:**  
        ```bash
        🔧 Starting wireguard install...
        ```
        User sees that WireGuard installation is starting.  
        No input required.

    - **Package installation:**  
        ```bash
        apt install wireguard
        ```
        Script installs the `wireguard` package from system repositories.  
        User observes installation progress (standard `apt` output).  
        If installation fails (e.g., missing repositories, no internet), user must troubleshoot manually.

    - **Configuration notice:**  
        ```bash
        ⚠️ Configuration files cannot be uploaded online due to security reasons. For setup, please contact info@pmr.si
        ```
        User is informed that configuration files will **not** be provided automatically.  
        To complete setup, the user must:  
        - Configure WireGuard manually **or**  
        - Contact **info@pmr.si** for support and secure configuration exchange.

    - **User input summary:**  
        No interactive input required during script execution.  
        User must take **post-installation action** (manual configuration or contacting administrator).  
        
        **Note:** Users requiring a licence (`category II - Slovenia`) must enable a **WireGuard** connection to a **pmr.si administrator**. Read [Licence file](https://github.com/Kovojunior/Svxlink/blob/main/LICENCE.txt) for more information. To setup accordingly contact info@pmr.si.
    <br></br>

8. `Bash healthcheck installer (depricated)`, installs an older version of bash healthcheck script. Depricated since 1.9.2025. It creates a background watchdog service to ensure SvxLink stays active. Since it does not take action to user or svxlink input, it is essentially a dumb version of Python script.

    - **Initial message:**  
        ```bash
        === Installing bash healthcheck script ===
        ```
        User sees that installation of the healthcheck mechanism has started.  
        No input required.  

    - **Script creation (`/usr/local/bin/svxlink_healthcheck.sh`):**  
        This script continuously monitors the **SvxLink service**.  
        Every `15` seconds it checks if the service is **active**:  
        - If **inactive**, it logs the event into `/var/log/svxlink_healthcheck.log` and attempts to restart SvxLink.  
        - If restart fails repeatedly, it increases the **restart counter**.  
        - If the maximum of `5` failed restarts is reached, the script stops and logs the error.  
        - If service recovers, counter resets to zero.  

    - **Permissions:**  
        ```bash
        chmod +x /usr/local/bin/svxlink_healthcheck.sh
        ```
        Makes the healthcheck script executable.  

    - **Service unit creation (`/etc/systemd/system/svxlink_healthcheck.service`):**  
        A new **systemd service** is defined, running the script in the background.  
        Configured with `Restart=always` to ensure persistence.  
        Runs as **root** user.  

    - **Service activation:**  
        ```bash
        systemctl daemon-reload
        systemctl enable svxlink_healthcheck.service
        systemctl start svxlink_healthcheck.service
        ```
        Reloads systemd, enables service to auto-start on boot, and launches it immediately.  

    - **Status output:**  
        ```bash
        Status of bash healthcheck script after install:
        ```
        Shows current status of the healthcheck service.  
        Displays last `5` log entries from **journalctl**.  

    - **Completion message:**  
        ```bash
        ✅ Healthcheck installed and run!
        ```
        Confirms successful installation and that the watchdog is active.  

    - 📌 What the script does:
        Monitors the **SvxLink service** continuously.  
        Automatically restarts SvxLink if it crashes or stops.  
        Logs all failures and restart attempts to `/var/log/svxlink_healthcheck.log`.  
        Stops after 5 consecutive failed restarts, preventing infinite restart loops.  
        Runs as a persistent background service under `systemd`.  

    - **User input summary:**  
        No user interaction required during installation.  
        After installation, user can check logs or status manually:  
        - `systemctl status svxlink_healthcheck.service`  
        - `tail -f /var/log/svxlink_healthcheck.log` for real-time output **or** `cat /var/log/svxlink_healthcheck.log` to print the file.
    <br></br>

9. `Full remover`, permanently removes **SvxLink** and all related components including these **installers**, **updaters** and **configurators**  ***except WireGuard***.
    - **Warning message:**  
        ```bash
        ⚠️ You are entering dangerous waters. This script will delete all data, remove the Svxlink program, its configurators, and all related libraries (except WireGuard). Are you sure? Press Enter to continue or CTRL+C to abort...
        ```
        User is asked to **confirm** uninstallation by pressing Enter.  
        To cancel, user must press **CTRL+C**.  

    - **Stop running services:**  
        ```bash
        systemctl stop svxlink
        systemctl stop svxlink_healthcheck.service
        systemctl stop svxlink_healthcheck_python.service
        ```
        Stops **SvxLink** and both healthcheck services (Bash and Python).  

    - **Remove packages and libraries:**  
        ```bash
        apt purge -y svxlink* g++ cmake make libsigc++-2.0-dev ...
        apt autoremove -y
        ```
        Uninstalls SvxLink and all its development dependencies and utilities.  
        Runs `autoremove` to clear unused libraries.  

    - **Remove user account:**  
        ```bash
        deluser --remove-home svxlink
        ```
        Deletes the system user `svxlink` and its home directory.  

    - **Remove healthcheck scripts and services:**  
        ```bash
        systemctl disable svxlink_healthcheck.service
        systemctl disable svxlink_healthcheck_python.service
        rm -f /etc/systemd/system/svxlink_healthcheck.service
        rm -f /etc/systemd/system/svxlink_healthcheck_python.service
        rm -f /usr/local/bin/svxlink_healthcheck.sh
        rm -f /usr/local/bin/svxlink_healthcheck.py
        systemctl daemon-reload
        ```
        Disables and deletes both watchdog services and their scripts.  

    - **Remove Python watchdog library:**  
        ```bash
        pip3 uninstall -y watchdog --break-system-packages
        ```
        Cleans up the **Python watchdog module** (used by the Python healthcheck).  

    - **Remove configuration directories:**  
        ```bash
        rm -rf 
        /etc/svxlink 
        /usr/share/svxlink 
        /var/log/svxlink 
        /var/log/svxlink_healthcheck 
        /var/log/svxlink_python 
        /usr/src/svxlink 
        /tmp/svxlink_install/AIOC_settings.sh
        /tmp/svxlink_install/FRN_settings.sh
        /tmp/svxlink_install/update_svxlink.sh 
        /tmp/svxlink_install/healthcheck.py
        ```
        Deletes all SvxLink config files, logs, sources, and temporary installation settings.  

    - **Completion message:**  
        ```bash
        ✅ Svxlink, configuration files and healthcheck successfully removed!
        ```
        Confirms that SvxLink and related components are gone.  

    - 📌 What the script does:
        Removes binaries, configs, logs, services, and dependencies.  
        Deletes the `svxlink` system user.  
        Cleans both **Bash** and **Python** watchdogs.  
        Ensures system is left in a clean state.  
        **Exception:** WireGuard remains installed (not touched).  

    - **User input summary:**  
        **One interaction required:** confirmation with **Enter** (or cancel with **CTRL+C**).  
        After confirmation, everything is automatic.  

---
<br></br>
---

## 2. FRN Settings Configurator for SvxLink

`FRN_settings.sh` is a Bash script designed to assist users in updating the **ModuleFrn.conf** configuration file for SvxLink, ensuring proper PMR.SI channel settings, user identification, and location information. The script also updates the **svxlink.conf** file with the user's callsign, making SvxLink ready for immediate use with the FRN network.

**Important notice: User must configure the FRN account beforehand. See [Java FRN Client - Please read](https://freeradionetwork.de/please_read.html) for more information!**

### 2.1 Components
The script is built using **standard Linux utilities** and **libraries**:
- **Bash** for scripting.  
- `sed` for in-place file modifications.  
- `grep` and `awk` for parsing configuration files.  
- `systemctl` for managing the SvxLink service.  

No external libraries are required beyond default Linux system tools.

### 2.2 Functionality
1. **Configuration file detection:**
The script targets the `ModuleFrn.conf` file located at `/etc/svxlink/svxlink.d/ModuleFrn.conf`. If the file does not exist, the script exits with an error message.

2. **Computer type detection:**
`get_computer_type()` identifies the type of single-board computer (SBC) running the script by reading `/etc/armbian-release` or `/proc/device-tree/model`, depending on installation. Supported types include **RPi4**, **RPi3**, **OPi3**, and **OPiZero**. Unknown boards are labeled as `UnknownARM`.

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

### 2.3 Usage
To run the script with root privileges:

```bash
mkdir -p /tmp/svxlink_install && cd /tmp/svxlink_install
wget -O FRN_settings.sh https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/FRN_settings.sh
sudo chmod +x FRN_settings.sh  
sudo ./FRN_settings.sh 
```
Upon execution, the script will prompt the user to confirm or modify settings such as EMAIL_ADDRESS, DYN_PASSWORD, CALLSIGN, USER, PMR446 channel, altitude, and location information. The script then updates configuration files, restarts the SvxLink service, and displays the service status along with the last 8 log entries.

After running the script, `ModuleFrn.conf` contains the updated FRN configuration, and `svxlink.conf` has the correct **CALLSIGN**. Backups of both files are stored as `ModuleFrn.conf.bak` and `svxlink.conf.bak`. The SvxLink service is restarted to apply the new settings, ensuring immediate operation with the FRN network.

### 2.4 User interaction
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


### 2.4.1 List of possible outcomes
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

## 3. AUTOMATIC PMR.SI CONFIGURATION UPDATER FOR SVXLINK
`update_svxlink.sh` is a Bash script designed to automate the update of **PMR.SI standard configuration files** and **sound files** for SvxLink. The script ensures that SvxLink is configured with the latest logic, module, and event scripts, as well as custom audio prompts, without manual intervention. Script by itself does not create backups for updates files so use with caution.

### 3.1 Components
The script is built using **standard Linux utilities** and libraries:
- **Bash** for scripting.
- **wget** for downloading files from GitHub.
- Linux file management commands such as `mkdir`, `chmod`, and `systemctl`.

No external libraries or packages beyond default Linux system tools are required.

### 3.2 Functionality
1. **File mapping and target paths:**
The script defines a list of **source URLs** and their corresponding **target paths** on the system using an associative array `files`. This includes configuration scripts (`.tcl` and `.conf`) in `/usr/share/svxlink/events.d` and `/etc/svxlink/svxlink.d`, as well as **custom sound files** in `/usr/share/svxlink/sounds/en_US/Frn`.

2. **Directory preparation:**
The script ensures that the target sound directory (`/usr/share/svxlink/sounds/en_US/Frn`) exists by creating it if necessary with `mkdir -p`.

3. **Download and update:**
For each entry in the `files` array, the script downloads the file from GitHub using `wget` and saves it to the specified target path. Successful updates are confirmed with a green success message, while failed downloads are flagged with a red error message. After downloading, it sets the correct file permissions using `chmod 644`.

4. **Service restart:**
Once all files are updated, the script restarts the `SvxLink` service using `systemctl restart svxlink` to apply the new configuration and audio files.

### 3.3 Usage
To execute the script with root privileges:

```bash
mkdir -p /tmp/svxlink_install && cd /tmp/svxlink_install
wget -O update_svxlink.sh https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/update_svxlink.sh
sudo chmod +x update_svxlink.sh
sudo bash update_svxlink.sh
```
Upon execution, the script will automatically update the PMR.SI configuration and sound files, ensuring that SvxLink runs with the latest standard. All critical operations, such as download status and file permissions, are logged and displayed in the terminal.

### 3.4. List of possible outcomes:
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

## 4. AUTOMATIC AIOC CONFIGURATOR FOR SVXLINK
`AIOC_settings.sh` is a Bash script designed to automatically configure the **AIOC (All-In-One-Cable)** audio interface for use with SvxLink, a software-based amateur radio transceiver. The script simplifies the setup of **playback**, **capture**, and **PTT (Push-To-Talk)** devices, ensuring that the `svxlink.conf` configuration file is correctly updated without manual editing. File is usually stored in `/etc/svxlink`. Currently Svxlink supports multiple connected TRX devices by configuring `Rx[0-9]` and `Tx[0-9]` code blocks. This script is only optimised for use of one connected TRX device!

### 4.1 Components
The script relies on **standard Linux utilities** and **libraries**:
- **Bash** – scripting language to orchestrate the setup.
- **ALSA utilities** (`aplay`, `arecord`) – used to detect connected audio devices.
- `sed` – for in-place modification of the `svxlink.conf` configuration file.
- Linux device interfaces – `/dev/ttyACM*` for detecting PTT hardware.

No external libraries or packages beyond the default Linux system tools are required.

### 4.2 Algorithm - step by step
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


### 4.3 Usage
To run the script, execute it with root privileges:
```bash
mkdir -p /tmp/svxlink_install && cd /tmp/svxlink_install
wget -O AIOC_settings.sh https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/AIOC_settings.sh
sudo chmod +x AIOC_settings.sh
sudo bash AIOC_settings.sh
```
After execution, the script will automatically configure `svxlink.conf` with the detected devices, readying SvxLink for immediate use with the AIOC interface. A backup of the previous configuration is stored as `svxlink.conf.bak` in the same directory.

### 4.4 List of possible outcomes
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
<br></br>
---

## 5. SMART PYTHON HEALTHCHECK FOR SVXLINK
This Python script provides an advanced health monitoring system for the SvxLink service. It ensures continuous operation by automatically detecting issues, attempting recovery, and notifying administrators via email when critical problems arise.
Before implementing this script, managing multiple SvxLink nodes was a daily challenge. Back when we had 20 repeaters and gateways, it was common for one or more to fail every day. Often, I didn’t even get a chance to check the logs, and simple issues wouldn’t resolve themselves. Each problem required manually connecting to the system and entering a few commands, which quickly became tedious and time-consuming.

For example, a common issue was a missing audio device or a stuck transmitter. Without the healthcheck, I had to SSH into the Orange Pi, inspect logs, and run a series of commands to restart SvxLink or reset USB devices. What could have been fixed in just a couple of commands often took 10–15 minutes per node, multiplied by the number of nodes, every single day.
This Python healthcheck automates all of that: it monitors logs in real time, detects errors, restarts services when needed, resets USB devices, and even sends email alerts. This means administrators can now focus on other tasks, knowing that the system handles routine failures automatically.

### 5.1 Why are the scripts aesthetics so “ugly”
If you’ve opened the Python healthcheck and noticed that it doesn’t have any fancy graphical interface—no windows, buttons, or modern dashboards—you might wonder why it looks so “plain” or even chaotic in the terminal. This is entirely by design, and there are several practical reasons for this approach.

The primary goal of this script is real-time monitoring of SvxLink. SvxLink is a system that handles voice transmissions and signal routing on repeaters and gateways, and problems can happen in seconds. To immediately identify a problem, the script uses text-based color codes in the terminal: blue for informational messages, green for normal watchdog signals, yellow for throttled email notifications, and red for errors, restarts, or forced stops. By having all output in the terminal, administrators can quickly scan lines of logs and instantly identify the severity of each event, without navigating through menus or clicking on anything.

Another crucial reason for the terminal-only interface is hardware limitations. Many SvxLink systems run on low-power devices like Raspberry Pi 1, Pi Zero, or Orange Pi Zero, which do not have enough CPU or RAM to run a full graphical desktop environment in real time and cannot reliably display graphics while also processing audio signals without dropping frames or creating delays. If the healthcheck tried to render fancy GUIs or graphical charts on these devices, it could slow down or even crash the system. A text-based interface is lightweight, predictable, and compatible with almost any Linux environment, even without X11 or Wayland.

SvxLink administrators rarely sit in front of the device, and most often the system is managed remotely via SSH. Text output can be viewed over a simple terminal session, even with low bandwidth, and the color-coded, structured messages make it easy to read remotely without downloading log files or opening a GUI.

The script is intentionally focused on functionality rather than appearance. Its job is to watch logs, detect errors, restart services, reset USB devices, and send email alerts. Visual aesthetics are secondary because a “pretty” display would not add any operational value and could even introduce unnecessary complexity or bugs.

Although it’s text-based, the output structure is consistent and color-coded, which makes it easy for more advanced users to pipe the output into other monitoring systems, parse logs automatically for reporting or analytics, and integrate with web dashboards later if desired, without changing the core functionality.

In short, the Python healthcheck looks “ugly” on purpose. Its design prioritizes speed and readability in real time, compatibility with low-resource devices, remote access via terminal, and reliable automated monitoring over aesthetics. This ensures that even on tiny single-board computers, SvxLink remains continuously monitored and recoverable without the need for a graphical desktop or high-end hardware. The “ugly” text interface is actually a feature, not a flaw, because it delivers maximum clarity and reliability under practical constraints.
<br></br>

### 5.2 Understanding key basics
#### 1. Watchdog, does the dog bite?
Watchdog signal (WDS) is a special "heartbeat" message that a program sends periodically to confirm it is still running correctly.  
F.e. `SimplexLogic: WDS signal` means that SvxLink is alive and actively responding.  
If the watchdog signal is missing, a **timeout** (`WDS_TIMEOUT`) is triggered. In practice, this means the program has frozen or crashed.  
The script resets the timer on every WDS signal and restarts `svxlink` if no signal arrives within the allowed time.  
This is common practice in many applications, from industrial controllers to operating systems, to prevent a "dead" process from staying blocked forever.  

#### 2. How can some "stupid" program know what error comes through its door?
To understand how this script detects problems, it is helpful to know about something called "regular expressions," or regex for short. Regex is a way for the computer to look for patterns or specific words in text. In this case, the script is constantly checking the SvxLink log files for lines that indicate errors. The log files are like a diary where SvxLink writes everything it does, including warnings, errors, and status messages.
For example, the script defines a pattern called ERRORS_REGEX:
```python
ERRORS_REGEX = re.compile(
    r"(error|failed|block|wrong|DR_SYSTEM_ERROR|DR_HOST_NOT_FOUND)",
    re.IGNORECASE
)
```
This tells the script to watch for any line in the logs that contains any of the words “error,” “failed,” “block,” “wrong,” or the codes “DR_SYSTEM_ERROR” and “DR_HOST_NOT_FOUND.” The option re.IGNORECASE means it does not matter if the letters are uppercase or lowercase. So “Error” and “error” will both be detected. 
When new lines appear in the SvxLink log, the script reads only the lines added since the last check. Each line is cleaned of extra spaces and then compared against the regex. If a line matches ERRORS_REGEX, the script treats it as an error. It will print a warning in the terminal so you can see it immediately, and it will also send an email notification to the administrator. If a line matches a special skip pattern (SKIP_ERRORS), the script ignores it for email purposes but may still log it for record keeping.

Think of regex as a filter or alarm system. Every new line in the log is like a message in an inbox. The regex reads the message and decides whether it is important and requires action, or whether it can be ignored. This allows the script to automatically react to problems without a person having to read through hundreds of lines manually.

For instance, if the log contains the line:
```text
[2025-08-25 10:15:03] ERROR: Open playback audio device failed
```

The regex finds the word “ERROR.” Since this is not skipped, the script prints a message in red:
```text
[ALERT] Svxlink error-level error detected: ERROR: Open playback audio device failed. No further action...
```
At the same time, it sends an email to notify the administrator. This way, the system can detect issues like missing audio devices or failed transmissions in real time, and take automatic action to restart SvxLink or reset devices if needed. 

In short, the combination of the WDS heartbeat and regex-based log monitoring allows the healthcheck script to keep SvxLink running smoothly without constant manual supervision. The heartbeat ensures the program itself is alive, and the regex scans the log to catch any errors that could otherwise go unnoticed until a human checks manually.
Read more about Regex here: [Regular Expression HOWTO](https://docs.python.org/3/howto/regex.html), [The Complete Guide to Regular Expressions (Regex)](https://coderpad.io/blog/development/the-complete-guide-to-regular-expressions-regex/).

#### 3. Terminal, how, why and who??
It is a way to interact with a computer using text commands instead of clicking buttons or using a graphical interface. On Linux systems, the terminal lets you type commands, run programs, and see outputs directly from the operating system. Think of it as a “command window” where you can talk to the computer and get responses in real time.

When you run the Python healthcheck script, for example by typing python3 healthcheck.py in the terminal, the program starts and begins monitoring the SvxLink logs immediately. Any messages, warnings, or errors that the script detects are printed directly to the terminal. These messages use colors to make them easy to read: blue for normal information, green for WDS heartbeat signals, yellow for pending email notifications, and red for errors or restarts. By displaying information in the terminal, you can watch the system operate in real time and see exactly what is happening.

You can see the terminal either directly on the device itself, if it has a screen attached, or remotely from another computer using an SSH connection. SSH (Secure Shell) is a way to securely log into a remote computer over a network. Putty is a program that allows you to do this from a Windows machine. You simply enter the IP address of the Raspberry Pi, Orange Pi, or other Linux device running SvxLink, provide your username and password, and you get a terminal window on your own computer that is connected to the remote system. More about Putty here: [How to Use PuTTY on Windows](https://www.ssh.com/academy/ssh/putty/windows).

Once connected via Putty or another SSH client, you can type commands just as if you were sitting in front of the device. You can start the healthcheck script manually by typing python3 healthcheck.py, or you can view logs, restart services, or check system status. Every output from the healthcheck script will appear in this terminal window. You can scroll through messages, watch them update live, and see errors highlighted in color, which makes it much easier to identify problems quickly.

In short, the terminal is the main way to interact with the system without a graphical interface. The healthcheck script uses it to show live updates, colored alerts, and important status messages. Whether you are directly at the device or connected remotely via Putty, the terminal provides a simple and immediate way to see how SvxLink is performing and to respond to any issues if needed.

#### 4. System service, please be my servant!
Linux Debian is an operating system, similar in purpose to Windows or macOS, but it is free, open-source, and highly customizable. It provides the core software needed to run applications, manage files, control hardware, and connect to networks. Unlike Windows, which relies heavily on graphical interfaces, Debian can run entirely without a graphical environment, using only the terminal. This is often referred to as “headless” mode. Running without a graphical environment means there are no windows, icons, or menus—everything is controlled through text commands in the terminal. This is particularly useful on low-power devices like Raspberry Pi, Orange Pi, or other small single-board computers, because it reduces resource usage and allows programs like SvxLink and the healthcheck script to run efficiently in real time.

In Debian and most Linux systems, services are background programs that start automatically and continue running without user intervention. These are managed by systemd, the system and service manager. The command systemctl is used to control these services. For example, systemctl start svxlink_healthcheck_python.service will start the healthcheck script as a background service, systemctl stop will stop it, and systemctl status will show whether it is running or if any errors have occurred. By running the healthcheck as a systemd service, it starts automatically when the device boots, runs continuously in the background, and can automatically restart if it crashes. This eliminates the need to manually start the script every time the device is powered on.

Running the healthcheck as a systemd service also provides better integration with the operating system. Systemd keeps track of the service’s state, logs its output, and can enforce limits or restart policies. For instance, if the healthcheck script stops unexpectedly, systemd can automatically attempt to restart it according to preconfigured rules. This ensures that SvxLink is continuously monitored and reduces the chance of downtime caused by crashes or freezes.

Debian provides a stable, lightweight, and flexible environment for running programs like SvxLink. The lack of a graphical interface allows the system to focus resources on essential tasks, while systemd and systemctl provide robust control over background services, ensuring that critical processes like the healthcheck script run reliably and automatically without constant human intervention.

#### 5. Wireguard, the strongest wire!
WireGuard is a modern, fast, and secure VPN (Virtual Private Network) solution that allows devices to communicate over the internet as if they were on the same local network. It encrypts all data sent between devices, which protects it from being intercepted or tampered with. In the context of the healthcheck and SvxLink system, WireGuard is often used to connect remote Raspberry Pi or Orange Pi devices to a central server securely. This way, administrators can access the devices and their terminals from anywhere without exposing sensitive network ports directly to the internet. WireGuard is lightweight, efficient, and works well even on small, low-power devices, making it ideal for monitoring multiple SvxLink nodes remotely.

Regarding configuration and credentials, such as  WireGuard settings or  Gmail app password for sending email alerts, these were intentionally not uploaded to GitHub or any public repository. This is because they are **sensitive information**. If they were made public, anyone could potentially access that email account, interfere with VPN connections, or gain control over SvxLink nodes. For security reasons, it is best practice to keep passwords, private keys, and configuration files private and store them securely on the device itself. 

As it was stated multiple times troughout this manual, users under **category II (Slovenia)** must enable Wireguard connection to the pmr.si administrator. Read more in chapter: **1.3.1 (7)**

#### 6. Why we use logs and how to read them
Logs, or log files, are records where programs write information about what they are doing. Think of them as a diary for your system: every time something important happens, like a message being received, a transmitter turning on, or an error occurring, SvxLink writes a note in its log. These logs are essential because they allow both the script and administrators to understand what is happening inside the system at any moment.

The healthcheck script continuously monitors these logs because it can detect problems as soon as they occur. By reading new lines in real time, the script knows if a transmitter is stuck, if an audio device is missing, or if any other error arises. This makes automated recovery possible, because the script doesn’t need to wait for someone to check the system manually—it reacts instantly based on what it reads in the logs.

If you are a beginner and want to see the logs yourself, you can use a simple terminal command. One common command is:
```bash
tail -f /var/log/svxlink/svxlink.log
```
This command opens the SvxLink log file and continuously displays any new lines as they are written, showing real-time updates in the terminal. You can also use other commands to explore logs in different ways. For example, `cat /var/log/svxlink/svxlink.log` will display the entire log file at once, `tail -n 100 /var/log/svxlink/svxlink.log` will show the last 100 lines, and `grep "ERROR" /var/log/svxlink/svxlink.log` will filter the log to show only lines containing the word "ERROR." The `sed` command can be used to search, replace, or format log content, for example highlighting certain parts of messages for easier reading.

Commands can be combined using a pipe `|`, which sends the output of one command directly into another. For example, you can use `cat /var/log/svxlink/svxlink.log | grep "ERROR"` to first display the full log with `cat` and then filter it to show only lines containing "ERROR" with `grep`. This is useful when you want to quickly find relevant information without scrolling through the entire log.

Another example is `tail -n 100 /var/log/svxlink/svxlink.log | grep "WDS"`, which shows the last 100 lines of the log and filters them to display only lines containing "WDS" signals. This way, you can focus on recent events and see only the messages you are interested in, combining commands to save time and increase efficiency.

By using these commands, you can examine log files at your own pace, find specific errors or warnings, and verify what the healthcheck script is monitoring and reacting to. Logs are the eyes and ears of the healthcheck script, telling it what is happening and allowing administrators to understand the system's activity in real time while also providing a record of past events for troubleshooting or analysis.

#### 7. But again, how does the script react?
If a regular status message appears, like a TX stop signal, the script resets its internal timer and prints a green message in the terminal. No further action is needed because everything is normal. 

Now imagine a problem occurs: the transmitter gets stuck and no TX stop signal is received. The script detects this by matching the log lines against the RESTART_ERRORS patterns. It immediately prints a red alert to the terminal, then attempts to recover the system. This involves resetting a USB device and restarting the SvxLink service. If the recovery is successful, the terminal shows status updates indicating the system is back to normal, and an email alert is sent to notify the administrator of what happened. 

Throughout this process, the administrator does not need to be physically present. They can monitor the script remotely through a terminal, for example via SSH and Putty, and see all actions in real time. This step-by-step flow—log detection, pattern matching, terminal alert, automatic recovery, and email notification—ensures that issues are addressed quickly and consistently without manual intervention. 

#### 8. Arghhh, I tried to use this script but failed! Why??
Even though the healthcheck script automates many tasks, beginners can still run into common issues that prevent it from working as expected. One frequent problem is that email notifications fail to send. This usually happens if the Gmail application password is incorrect, missing, or misconfigured. It’s important to double-check that the `SENDER` email address, the app password, and the `RECIPIENT` address are all entered correctly in the configuration. Without these, the script can detect errors but won’t be able to alert the administrator.

Another common issue involves USB devices, like the AIOC cable or audio interfaces. If the device is not properly connected, powered, or recognized by the system, the script cannot reset it automatically. Beginners should ensure that the USB device is physically connected, has the correct permissions, and is visible to the operating system. Commands like `lsusb` can help verify that the system detects the hardware. 

By understanding these common mistakes and performing simple checks, users can avoid unnecessary confusion and ensure that the healthcheck script operates smoothly, reliably monitoring SvxLink and taking corrective action when needed.
<br></br>

### 5.3 Components
- **Python Standard Libraries**: `time`, `re`, `subprocess`, `smtplib`, `os`, `sys`, `threading`, `datetime`, `fcntl`, `urllib`.
- **Email Support**: Uses `smtplib` and `MIMEText` for Gmail-based alerts.
- **Watchdog**: Relies on `watchdog` (`Observer`, `FileSystemEventHandler`) to monitor log file changes in real time.
- **Configuration**:
    - `svxlink.conf` → RX/TX/WDS timeouts.
    - `ModuleFrn.conf` → Callsign and gateway name.
    - **Note:** This script **must be configured** in order to send out EMail notifitcations. Either input your EMail address, app password and recipient EMail address manually or use installer.sh script.
- **Logging**:
    - `/var/log/svxlink` (SvxLink logs)
    - `/var/log/svxlink_healthcheck.log` (healthcheck logs)
    - `/var/log/svxlink_python` (Python healthcheck logs)
    - `/var/log/svxlink_backup` (backup of SvxLink logs)
<br></br>

### 5.4 Functionality
1. **Real-time log monitoring**: Watches SvxLink logs for errors, warnings, and signals.
2. **Automatic service control**:
    - Restarts `svxlink` service upon detecting freezes or hardware faults.
3. **Stops the service** if unrecoverable errors occur.
4. **Hardware handling**:
    - Detects and resets **AIOC (All-In-One-Cable)** USB devices.
    - Downloads and runs `AIOC_settings.sh` when needed.
5. **Error categorization**:
    - `ERRORS_REGEX` → non-critical errors, logged and reported.
    - `RESTART_ERRORS` → forces AIOC reset and SvxLink restart.
    - `STOP_ERRORS` → stops SvxLink entirely.
6. **Timers**:
    - RX freeze detection.
    - TX stuck-transmit detection.
7. **Watchdog (WDS)** timeout monitoring.
8. **Email alerts**:
    - Sends pending error reports via Gmail.
    - Includes last 100 lines from:
        - Pending errors
        - Python healthcheck logs
        - SvxLink logs
    - Implements throttling and retry mechanisms.
<br></br>

### 5.5 Usage
The script is started as a **systemd service** (`svxlink_healthcheck_python.service`).
Runs continuously in the background, monitoring `/var/log/svxlink`. 

Requires configuration of:
- `SENDER` (administrator Gmail address).
- `PASSWORD` (application password for Gmail).
- `RECIPIENT` (email for alerts).

Administrator should ensure:
- AIOC device is connected (if used).
- Correct permissions to access logs and USB devices.
<br></br>

### 5.6 List of predefined svxlink error strings - Regex
- **RESTART_ERRORS**, Python script orders AIOC reset with AIOC configurator and forcibly restarts Svxlink:
    - `ERROR: Open playback audio device failed`
    - `ERROR: Open capture audio device failed`
    - `open serial port: No such file or directory`
    - `WARNING: (RX|TX) timer exceeded pmr.si limitations`
    - `snd_pcm_prepare failed`
    - `unrecoverable error`  

- **STOP_ERRORS**, when this stop-level error occurs, Svxlink is forcibly closed immediatelly:
    - `<AL>BLOCK</AL>`
    - `<AL>WRONG</AL>`  

- **ERRORS_REGEX**, list of other possible errors script actively listens for: 
    - `error`
    - `failed`
    - `block`
    - `wrong`
    - `DR_SYSTEM_ERROR`
    - `DR_HOST_NOT_FOUND`

    These errors are just logged but script takes no immediate restart action. It does send email notification however.
<br></br> 

### 5.7 List of Possible Outcomes
1. ✅ **Normal operation**  
   SvxLink logs are monitored, RX/TX/WDS timers are tracked, no user action required.  

    - 🔹 **RX squelch opened**  
        - **Cause**: incoming signal detected, squelch timer started.  
        - **Log output**: `[INFO] Squelch opened, timer started.`  
        - **Color**: Blue (`BLUE`).  
    - 🔹 **RX squelch closed**  
        - **Cause**: no more incoming signal, squelch timer cleared.  
        - **Log output**: `[INFO] Squelch closed, timer cleared.`  
        - **Color**: Blue (`BLUE`).  
    - 🔹 **TX transmitter ON**  
        - **Cause**: transmission started, TX timer started.  
        - **Log output**: `[INFO] Transmitter ON, TX timer started.`  
        - **Color**: Blue (`BLUE`).  
    - 🔹 **TX transmitter OFF**  
        - **Cause**: transmission ended, TX timer cleared.  
        - **Log output**: `[INFO] Transmitter OFF, TX timer cleared.`  
        - **Color**: Blue (`BLUE`).  
    - 🟢 **WDS watchdog signal received**  
        - **Cause**: watchdog signal received from SvxLink, timer successfully reset.  
        - **Log output**: `[INFO] WDS signal detected, watchdog timer reset.`  
        - **Color**: Green (`GREEN`). 
    <br></br> 
    

2. 🔄 **SvxLink restart**:  
    Triggered when:
    - RX or TX timers exceed configured thresholds.
    - No WDS signal received within timeout.
    - Restart-level error detected in logs.

    **Note:** Restart does not necessarily resolve the issue by itself. This script is configured to keep listening for errors even after such action.

    - **Cause**: a critical error preventing proper operation (e.g. missing audio device, missing serial port, frozen TX/RX).  
    - **Log output**: `[ALERT] Svxlink critical error detected: {error_str}. Attempting a svxlink environment restart...({failed_resets})`  
    - **Color**: Red (`RED`).
    <br></br>

3. 🔌 **AIOC reset + SvxLink restart**:  
    Triggered when USB or critical errors are detected (`snd_pcm_prepare failed`, missing serial port, audio device failure, etc.).
    <br></br>

4. ⛔ **Forced stop**:  
    Triggered when a STOP-level error (e.g., `<AL>BLOCK</AL>`) is detected. SvxLink and the healthcheck script terminate.

    - **Cause**: SvxLink entered a blocked state where continuing is impossible (e.g. `<AL>BLOCK</AL>`).  
    - **Log output**: `[ALERT] Svxlink stop-level error detected: {error_str}. Stopping svxlink service and this script...`  
    - **Color**: Red (`RED`).
    <br></br>

5. ⚠️ **Error detected, no immediate action**  
    - **Cause**: a common error detected in the logs (e.g. "error", "failed") that is not immediately critical.  
    - **Log output**: `[ALERT] Svxlink error-level error detected: {error_str}. No further action...`  
    - **Color**: Red (`RED`).
    <br></br>

6. 🚫 **Ignored errors**  
    - 🔹 *Ignored in SvxLink logs*:  
        - **Cause**: soft errors (e.g. TX stuck too long, RX open too long) are ignored because other handlers will catch the real condition.  
        - **Log output**: `[INFO] Ignored error: {error_str}`  
        - **Color**: Blue (`BLUE`).  
    - 🔹 *Ignored in email scheduler*:  
        - **Cause**: an error detected but skipped by the email scheduler to avoid sending unnecessary alerts.  
        - **Log output**: `[INFO] Ignored error for email scheduling: {error_str}`  
        - **Color**: Blue (`BLUE`). 
    <br></br>

7. 📧 **Email notifications**  
    Sent when restart or stop conditions occur, or when pending errors are flushed.  
    - 🟢 *Successful email*:  
        - **Cause**: email notification sent successfully, pending error buffer cleared.  
        - **Log output**: `[INFO] Email sent successfully!`  
        - **Color**: Green (`GREEN`).  
    - 🔴 *Email sending failure*:  
        - **Cause**: mail server unreachable or invalid Gmail login credentials.  
        - **Log output**: `[ALERT] Error while sending email: {e}. Will retry in {current_retry_interval}s`  
        - **Color**: Red (`RED`).  
    - 🟡 *Email throttle active*:  
        - **Cause**: email throttle still in effect, error stored in buffer.  
        - **Log output**: `[INFO] EMail sender on cooldown, added to pending buffer.`  
        - **Color**: Yellow (`YELLOW`).  
    <br></br>

8. 🕒 **Backoff mechanism**:  
    - If repeated failures occur, restart attempts slow down.
    - WDS timeout increases gradually up to one day.
    - Maximum failed resets (59) reached → restart prevention is engaged.
---