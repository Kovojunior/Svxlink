import time
import re
import subprocess
import smtplib
import fcntl
import os
import signal
import urllib.request
import sys
import threading
from datetime import datetime, timedelta
from email.mime.text import MIMEText
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Settings
SERVICE = "svxlink"
MAX_RESTARTS = 5 # Depricated
RESTART_COUNT = 0
LOG_FILE = "/var/log/svxlink_healthcheck.log"
RESET_TIMEOUT = 2
TOLERANCE = 15
TIMEOUT_RX = 0
TIMEOUT_TX = 0
WDS_TIMEOUT = 0
WDS_TIMEOUT_INIT = 0
TIMEOUT_RX_DEFAULT = 180 + TOLERANCE 
TIMEOUT_TX_DEFAULT = 180 + TOLERANCE
WDS_TIMEOUT_DEFAULT = 180 + TOLERANCE
WDS_TIMEOUT_MAX = 86400 # 1 day
MAX_FAILED_RESETS = 59 # Maximum number of failed resets in a row, runs up to 30 days
EMAIL_THROTTLE = 3600 # One hour
EMAIL_RETRY_INTERVAL = 300 # 5 minutes
MAX_EMAIL_RETRY_INTERVAL = 86400 # 1 day

# ! Configure before using this script! Not included on github
SENDER = "SENDER_EMAIL"
PASSWORD = "SENDER_EMAIL_APP_PASSWORD"
RECIPIENT = "RECIPIENT_EMAIL"
# !!!

LOG_SVXLINK = "/var/log/svxlink"
LOG_SVXLINK_BACKUP = "/var/log/svxlink_backup"
LOG_HEALTH = "/var/log/svxlink_healthcheck"
CONFIG_FILE = "/etc/svxlink/svxlink.d/ModuleFrn.conf"
SVXLINK_CONFIG = "/etc/svxlink/svxlink.conf"
OUTPUT_LOG_FILE = "/var/log/svxlink_python"

# Error regex - no action: TO-DO check when server grants DR_REMOTE_DISCONNECTED
ERRORS_REGEX = re.compile(
    r"(error|failed|block|wrong|DR_SYSTEM_ERROR|DR_HOST_NOT_FOUND)",
    re.IGNORECASE
)
# Error regex - svxlink restart, currently 'WARNING: (RX|TX) timer exceeded pmr.si limitations' not in use in svxlink
RESTART_ERRORS = re.compile(
    r"(ERROR: Open (playback|capture) audio device failed|open serial port: No such file or directory|WARNING: (RX|TX) timer exceeded pmr.si limitations|snd_pcm_prepare failed|unrecoverable error)",
    re.IGNORECASE
)
# Error regex - stops svxlink
STOP_ERRORS = re.compile(
    r"(<AL>(BLOCK|WRONG)</AL>)",
    re.IGNORECASE
)
# Ignores all lines that contain the following regex - avoiding users tempering with this script
IGNORE_REGEX = re.compile(r"-- <S>")
# Skips error so handler can catch a "better" line 
SKIP_ERRORS = re.compile(
    r'(QSO errored, deactivating module'
    r'|ERROR: Audio device failed. Trying to reopen'
    r'|ERROR: Transmitter Tx[0-9] have been active for too long. Turning it off'
    r'|WARNING: The squelch for "Rx[0-9]" was open for too long. Forcing it closed)',
    re.IGNORECASE
)

# AIOC settings
AIOC_LOCAL = "/tmp/AIOC_settings.sh"
AIOC_NAME = "All-In-One-Cable"
USBDEVFS_RESET = 21780

# ANSI colors
RESET = "\033[0m"
BOLD = "\033[1m"
YELLOW = "\033[1;33m"  
RED = "\033[1;31m"
GREEN = "\033[1;32m"  
BLUE = "\033[1;34m"

# For RX and TX timers 
squelch_open_time = None
squelch_timer = None
tx_on_time = None
tx_timer = None
wds_timer = None
failed_resets = 0

# EMail settings
last_email_time = None
pending_errors = []
current_retry_interval = EMAIL_RETRY_INTERVAL
first_email = True
last_email_success = True
email_sending_lock = threading.Lock()  # global flag for sending

# Booleans
is_restarting = False # for checking if svxlink is restarting at the moment
keep_blocked = False

# Threading settings
lock = threading.Lock()

# --- Functions --- #
# --- EMail functions --- #
# Sends an Email
def send_pending_errors():
    global pending_errors, last_email_time, current_retry_interval, last_email_success, email_sending_lock 
    global SENDER, PASSWORD, RECIPIENT, LOG_SVXLINK, OUTPUT_LOG_FILE

    with email_sending_lock:  # samo ena nit pošilja email hkrati
        if not pending_errors:
            return True

        subject = f"[{gateway_name()} Svxlink Alert]"
        content = f"""{subject}

    Dear Gateway Administrator,
    The Svxlink node has detected one or more critical issues during operation:
    """ + "\n".join(f"- {e}" for e in pending_errors) + """

    For diagnostic purposes, the following log excerpts are included:
    --------------------------------------------------------------------------------
    1) pending errors:
    """ + "\n".join(pending_errors) + """

    2) last 200 lines of Python HealthCheck script:
    """ + "\n".join(tail_file_since_last_email(OUTPUT_LOG_FILE, 200)) + """

    3) last 300 lines of Svxlink log:
    """ + "\n".join(tail_file_since_last_email(LOG_SVXLINK, 300)) + """
    --------------------------------------------------------------------------------
    This message has been generated automatically. 
    Please review the errors above and take appropriate corrective actions.
    """

        msg = MIMEText(content)
        msg["Subject"] = subject
        msg["From"] = SENDER
        msg["To"] = RECIPIENT

        try:
            log_print("[INFO] Attempting to send email...", YELLOW)
            with smtplib.SMTP("smtp.gmail.com", 587) as server:
                server.starttls()
                server.login(SENDER, PASSWORD)
                server.send_message(msg)

            log_print("[INFO] Email sent successfully!", GREEN)
            pending_errors = []
            last_email_time = datetime.now()
            current_retry_interval = EMAIL_RETRY_INTERVAL
            last_email_success = True
            return True

        except Exception as e:
            now = datetime.now()
            log_str = now.strftime("%d-%m-%Y %H:%M:%S")
            log_print(f"[ALERT] Error while sending email: {e}. Will retry in {current_retry_interval}s", RED)
            pending_errors.append(f"{log_str}: {e}")
            last_email_time = now 
            
            # exponential backoff
            current_retry_interval = min(int(current_retry_interval * 1.2), MAX_EMAIL_RETRY_INTERVAL)
            last_email_success = False
            return False

# Schedules an error for Email sending
def schedule_gmail(error_str, force_send=False):
    global pending_errors, last_email_time, first_email, last_email_success, EMAIL_THROTTLE

    pending_errors.append(error_str)
    now = datetime.now()
    can_send = False

    if force_send:
        can_send = True
    elif first_email:
        can_send = True
        first_email = False
    elif last_email_success:
        if last_email_time is None or (now - last_email_time).total_seconds() >= EMAIL_THROTTLE:
            can_send = True
    else:
        if last_email_time is None or (now - last_email_time).total_seconds() >= current_retry_interval:
            can_send = True

    if can_send:
        if not email_sending_lock.locked():  
            threading.Thread(target=send_pending_errors).start()
    else:
        log_print("[INFO] EMail sender on cooldown, added to pending buffer.", YELLOW)

# Periodically tries to send pending errors if the last attempt failed
def periodic_email_sender():
    global pending_errors, last_email_time, current_retry_interval, last_email_success, EMAIL_THROTTLE

    while True:
        now = datetime.now()
        if pending_errors:
            if not email_sending_lock.locked():
                if last_email_success:
                    if last_email_time is None or (now - last_email_time).total_seconds() >= EMAIL_THROTTLE:
                        threading.Thread(target=send_pending_errors).start()
                else:
                    if last_email_time is None or (now - last_email_time).total_seconds() >= current_retry_interval:
                        threading.Thread(target=send_pending_errors).start()
        time.sleep(5) 
# --- End: EMail functions --- #         

# --- LogHandler --- #
class LogHandler(FileSystemEventHandler):
    def __init__(self):
        super().__init__()
        with open(LOG_SVXLINK, "r", encoding="utf-8", errors="replace") as f:
            f.seek(0, os.SEEK_END)
            self.position = f.tell()

    def on_modified(self, event):
        global squelch_open_time, squelch_timer, tx_on_time, tx_timer, wds_timer, keep_blocked, failed_resets, TIMEOUT_RX, TIMEOUT_TX, MAX_FAILED_RESETS, LOG_SVXLINK, IGNORE_REGEX, WDS_TIMEOUT, WDS_TIMEOUT_INIT, RESTART_ERRORS, STOP_ERRORS, SKIP_ERRORS

        if event.src_path != LOG_SVXLINK:
            return

        with open(LOG_SVXLINK, "r", encoding="utf-8", errors="replace") as f:
            f.seek(self.position)
            new_lines = f.readlines()
            self.position = f.tell()
            #log_print(new_lines, YELLOW)

        for line in new_lines:
            line = line.strip()

            # Ignores all user data - avoiding tempering with this script
            if IGNORE_REGEX.search(line):
                continue

            # Executes RX checker logic
            if "Rx1: The squelch is OPEN" in line:
                with lock:
                    squelch_open_time = datetime.now()
                    if squelch_timer:
                        squelch_timer.cancel()
                    squelch_timer = threading.Timer(TIMEOUT_RX, check_freeze_rx)
                    squelch_timer.start()
                    log_print("[INFO] Squelch opened, timer started.", BLUE)
            elif "Rx1: The squelch is CLOSED" in line: # also works for Rx1: The squelch is CLOSED (TIMEOUT)
                with lock:
                    if squelch_timer:
                        squelch_timer.cancel()
                        squelch_timer = None
                        log_print("[INFO] Squelch closed, timer cleared.", BLUE)
                    squelch_open_time = None

            # Executes TX checker logic
            elif "Tx1: Turning the transmitter ON" in line:
                with lock:
                    tx_on_time = datetime.now()
                    if tx_timer:
                        tx_timer.cancel()
                    tx_timer = threading.Timer(TIMEOUT_TX, check_freeze_tx)
                    tx_timer.start()
                    log_print("[INFO] Transmitter ON, TX timer started.", BLUE)
            elif "Tx1: Turning the transmitter OFF" in line or "ERROR: Transmitter Tx1 have been active for too long. Turning it off" in line:
                with lock:
                    if tx_timer:
                        tx_timer.cancel()
                        tx_timer = None
                        log_print("[INFO] Transmitter OFF, TX timer cleared.", BLUE)
                    else:
                        tx_on_time = None

            # Executes forced svxlink restart due to missing watchdog (WDS) signal
            elif "SimplexLogic: WDS signal" in line and not keep_blocked and (failed_resets < MAX_FAILED_RESETS):
                with lock:
                    WDS_TIMEOUT = WDS_TIMEOUT_INIT
                    start_wds_timer()
                    #log_print("[INFO] WDS signal detected, watchdog timer reset.", BLUE)

            # Executes forced svxlink and AIOC restart due to critical error
            elif RESTART_ERRORS.search(line) and not is_restarting and (failed_resets < MAX_FAILED_RESETS):
                with lock:
                    match = RESTART_ERRORS.search(line)
                    if match:
                        error_str = match.group(0)
                        log_print(f"[ALERT] Svxlink critical error detected: {error_str}. Attempting a svxlink environment restart...({failed_resets})", RED)
                        schedule_gmail(error_str, force_send=False)
                        reset_aioc_with_restart()

            # Executes full stop
            elif STOP_ERRORS.search(line):
                with lock:
                    match = STOP_ERRORS.search(line)
                    if match:
                        error_str = match.group(0)
                        log_print(f"[ALERT] Svxlink stop-level error detected: {error_str}. Stopping svxlink service and this script...", RED)
                        keep_blocked = True
                        schedule_gmail(error_str, force_send=True)
                        time.sleep(5)
                        force_stop()

            # Sends an error message but does not take further action
            elif ERRORS_REGEX.search(line):
                with lock:
                    match = ERRORS_REGEX.search(line)
                    if match:
                        error_str = line
                        if not SKIP_ERRORS.search(error_str): # Skips errors for handler to catch a "better" line for EMail sender
                            log_print(f"[ALERT] Svxlink error-level error detected: {error_str}. No further action...", RED)
                            schedule_gmail(error_str, force_send=False)
                        else:
                            log_print(f"[INFO] Ignored error: {error_str}", BLUE)
# --- End: LogHandler --- #

# --- Mischelaneous --- #
# Gets SQL_TIMEOUT from /etc/svxlink/svxlink.conf
def get_sql_timeout():
    global TIMEOUT_RX, TIMEOUT_RX_DEFAULT, TOLERANCE, SVXLINK_CONFIG
    try:
        with open(SVXLINK_CONFIG, "r", encoding="utf-8", errors="replace") as f:
            for line in f:
                match = re.match(r"\s*SQL_TIMEOUT\s*=\s*(\d+)", line)
                if match:
                    TIMEOUT_RX = int(match.group(1)) + TOLERANCE
                    log_print(f"[SYSTEM] SQL_TIMEOUT set to {TIMEOUT_RX} (with tolerance).", GREEN)
                    return True
        TIMEOUT_RX = TIMEOUT_RX_DEFAULT
        log_print(f"[WARNING] SQL_TIMEOUT not found in svxlink.conf. Using {TIMEOUT_RX} instead", YELLOW)
        return False
    except Exception as e:
        log_print(f"[ERROR] Could not read SQL_TIMEOUT: {e}", RED)
        return False
    
# Gets TIMEOUT from /etc/svxlink/svxlink.conf
def get_timeout():
    global TIMEOUT_TX, TIMEOUT_TX_DEFAULT, TOLERANCE, SVXLINK_CONFIG
    try:
        with open(SVXLINK_CONFIG, "r", encoding="utf-8", errors="replace") as f:
            for line in f:
                match = re.match(r"\s*TIMEOUT\s*=\s*(\d+)", line)
                if match:
                    TIMEOUT_TX = int(match.group(1)) + TOLERANCE
                    log_print(f"[SYSTEM] TIMEOUT set to {TIMEOUT_TX} (with tolerance).", GREEN)
                    return True
        TIMEOUT_TX = TIMEOUT_TX_DEFAULT
        log_print(f"[WARNING] TIMEOUT not found in svxlink.conf. Using {TIMEOUT_TX} instead", YELLOW)
        return False
    except Exception as e:
        log_print(f"[ERROR] Could not read TIMEOUT: {e}", RED)
        return False
    
# Gets WDS_SIGNAL_INTERVAL from /etc/svxlink/svxlink.conf
def get_wds_signal_interval():
    global WDS_TIMEOUT_DEFAULT, TOLERANCE, WDS_TIMEOUT_INIT, WDS_TIMEOUT, SVXLINK_CONFIG
    try:
        with open(SVXLINK_CONFIG, "r", encoding="utf-8", errors="replace") as f:
            for line in f:
                match = re.match(r"\s*WDS_SIGNAL_INTERVAL\s*=\s*(\d+)", line)
                if match:
                    WDS_TIMEOUT_INIT = int(match.group(1)) * 60 + TOLERANCE
                    WDS_TIMEOUT = WDS_TIMEOUT_INIT
                    log_print(f"[SYSTEM] WDS_TIMEOUT_INIT set to {WDS_TIMEOUT_INIT} (with tolerance).", GREEN)
                    return True
        log_print("[WARNING] WDS_SIGNAL_INTERVAL not found in svxlink.conf", YELLOW)
        WDS_TIMEOUT_INIT = WDS_TIMEOUT_DEFAULT
        WDS_TIMEOUT = WDS_TIMEOUT_INIT
        return False
    except Exception as e:
        log_print(f"[ERROR] Could not read WDS_SIGNAL_INTERVAL: {e}", RED)
        return False
    
# Get name of a gateway from config
def gateway_name():
    global CONFIG_FILE
    try:
        out = subprocess.check_output(
            f"grep CALLSIGN_AND_USER {CONFIG_FILE}", shell=True, text=True
        ).strip()
        return out.split("=")[1].strip('"')
    except Exception as e:
        log_print(f"[SYSTEM] Cannot read CALLSIGN_AND_USER from config: {e}", RED)
        return "UNKNOWN"
# --- End: Mischelaneous --- #

# --- Loggers --- #
# Logs into terminal (with color) and output file
def log_print(msg, color=RESET):
    global OUTPUT_LOG_FILE
    timestamp = datetime.now().strftime("%a %b %d %H:%M:%S %Y")
    colored_msg = f"{color}[{timestamp}] {msg}{RESET}"
    print(colored_msg)
    with open(OUTPUT_LOG_FILE, "a", encoding="utf-8", errors="replace") as f:
        f.write(f"{timestamp}: {msg}\n")

# Logs into terminal only
def log(msg, color=RESET):
    global LOG_FILE
    timestamp = datetime.now().strftime("%d-%m-%Y %H:%M:%S")
    line = f"{timestamp}: {msg}"
    print(f"{color}{line}{RESET}")
    with open(LOG_FILE, "a", encoding="utf-8", errors="replace") as f:
        f.write(line + "\n")

# Backups and clears log
def backup_and_clear_log_and_reset_handler(old_handler=None):
    global event_handler, LOG_SVXLINK, LOG_SVXLINK_BACKUP
    try:
        # Backup
        with open(LOG_SVXLINK, "r", encoding="utf-8", errors="replace") as original, open(LOG_SVXLINK_BACKUP, "a") as backup:
            backup.write(original.read())

        # Truncate
        open(LOG_SVXLINK, "w", encoding="utf-8", errors="replace")

        # Just reset position on current handler
        if old_handler:
            with open(LOG_SVXLINK, "r", encoding="utf-8", errors="replace") as f:
                f.seek(0, os.SEEK_END)
                old_handler.position = f.tell()

        log_print(f"[SYSTEM] {LOG_SVXLINK} has been backed up, cleared, and handler reset.", GREEN)
        return True
    except Exception as e:
        log_print(f"[SYSTEM] Error while resetting log: {e}", RED)
        return False

# Tail last n lines of a file
def tail_file(filename, n=10):
    try:
        out = subprocess.check_output(["tail", "-n", str(n), filename], text=True)
        return out
    except Exception as e:
        log_print(f"[SYSTEM] Cannot read {filename}: {e}", RED)
        return ""
    
from datetime import datetime

# Tail lines after last_email_time (max 300)
def tail_file_since_last_email(filename, max_lines=300):
    global last_email_time

    try:
        out = subprocess.check_output(
            ["tail", "-n", "500", filename],
            text=True,
            errors="replace"
        )
        lines = out.splitlines()
    except Exception as e:
        log_print(f"[SYSTEM] Cannot read {filename}: {e}", RED)
        return []

    result = []
    for line in lines:
        ts = None

        # --- Format 1: Svxlink (Thu Aug 21 23:55:12 2025)
        try:
            ts_str = line[:24] 
            ts = datetime.strptime(ts_str, "%a %b %d %H:%M:%S %Y")
        except Exception:
            pass

        if last_email_time is None or (ts and ts > last_email_time):
            result.append(line)

    if len(result) > max_lines:
        result = result[-max_lines:]
        result.append(f"There were more than {max_lines} lines in the file, printing only last {max_lines}...")

    return result
# --- End: Loggers --- #

# --- USB scripts --- #
# Finds "AIOC or All-In-One-Cable" for reset function
def find_usb_device_by_name(name=AIOC_NAME):
    try:
        out = subprocess.check_output("lsusb", text=True).splitlines()
        for line in out:
            if name.lower() in line.lower():
                parts = line.split()
                vid, pid = parts[5].split(":")
                bus = parts[1]
                dev = parts[3].strip(":")
                dev_path = f"/dev/bus/usb/{bus}/{dev}"
                device = {
                    "vid": vid,
                    "pid": pid,
                    "bus": bus,
                    "dev": dev,
                    "dev_path": dev_path,
                    "raw_line": line,
                }
                log_print(f"[SYSTEM] Found USB device: {device}", GREEN)
                return device

        log_print(f"[SYSTEM] Script couldn't find a device called' {name}'.", RED)
        return None

    except Exception as e:
        log_print(f"[SYSTEM] Script encountered an error when searching for a device called '{name}': {e}", RED)
        return None

# Resets given USB device
def reset_aioc_device(name=AIOC_NAME):
    global RESET_TIMEOUT
    try:
        device = find_usb_device_by_name(name)
        if not device:
            log_print(f"[SYSTEM] USB device '{name}' was not found, could not be reset.", RED)
            return False

        dev_path = device["dev_path"]
        fd = os.open(dev_path, os.O_WRONLY)
        fcntl.ioctl(fd, USBDEVFS_RESET, 0)
        os.close(fd)

        log_print(
            f"[SYSTEM] USB device '{name}' ({device['vid']}:{device['pid']}, {dev_path}) successfully reset.",
            GREEN,
        )
        time.sleep(RESET_TIMEOUT)
        return True

    except Exception as e:
        log_print(f"[SYSTEM] Script encountered an error when resetting '{name}': {e}", RED)
        return False
    
# Downloads automatic AIOC configurator
def download_aioc_script():
    try:
        url = "https://raw.githubusercontent.com/Kovojunior/Svxlink/main/installer/AIOC_settings.sh"
        urllib.request.urlretrieve(url, AIOC_LOCAL)
        os.chmod(AIOC_LOCAL, 0o755)
        log_print(f"[SYSTEM] AIOC_settings.sh script downloaded successfully.", GREEN)
        return True
    except Exception as e:
        log_print(f"[SYSTEM] Script encountered an error when downloading AIOC_settings.sh: {e}", RED)
        return False
    
# Checks if AIOC configurator is already installed
def ensure_aioc_script():
    if os.path.isfile(AIOC_LOCAL):
        log_print(f"[SYSTEM] {AIOC_LOCAL} script already exsists.", GREEN)
        return True
    else:
        log_print(f"[SYSTEM] AIOC_settings.sh script missing in /tmp, executing download...", YELLOW)
        return download_aioc_script()

# Runs AIOC configurator
def run_aioc_settings():
    if not ensure_aioc_script():
        log_print(f"[SYSTEM] Cannot run AIOC_settings.sh because the script could not be downloaded.", RED)
        return False

    try:

        subprocess.run([AIOC_LOCAL], check=True)
        log_print(f"[SYSTEM] {AIOC_LOCAL} script executed successfully.", GREEN)
        time.sleep(1)
        return True
    except subprocess.CalledProcessError as e:
        log_print(f"[SYSTEM] Error while executing {AIOC_LOCAL}: {e}", RED)
        return False
    except Exception as e:
        log_print(f"[SYSTEM] Error starting {AIOC_LOCAL}: {e}", RED)
        return False
    
# Resets AIOC and executes a svxlink restart
def reset_aioc_with_restart():
    global is_restarting, failed_resets, MAX_FAILED_RESETS, WDS_TIMEOUT, WDS_TIMEOUT_MAX
    is_restarting = True
    try:
        if failed_resets >= MAX_FAILED_RESETS:
            log_print(f"[ALERT] Restart of 'svxlink' blocked. Too many failed attempts...({failed_resets})", RED)
            schedule_gmail(f"Svxlink has exceeded {MAX_FAILED_RESETS} failed resets! Stopping services.", force_send=True)
            time.sleep(5)
            force_stop()
            return False

        time.sleep(1)
        success = stop_svxlink() and backup_and_clear_log_and_reset_handler(old_handler=event_handler) and reset_aioc_device(AIOC_NAME) and run_aioc_settings() and restart_service("svxlink")
        if success:
            log_print("[SYSTEM] AIOC device reconfigured successfully and svxlink restarted.", GREEN)
            failed_resets = 0
            return True
        else:
            #failed_resets += 1
            #WDS_TIMEOUT = min(int(WDS_TIMEOUT * 1.2), WDS_TIMEOUT_MAX)
            log_print(f"[SYSTEM] AIOC - Svxlink reconfiguration failure...({failed_resets}), WDS timer restared with backoff and set to {WDS_TIMEOUT}s", RED)
            start_wds_timer()
            return False
    finally:
        is_restarting = False

# --- End: USB scripts #

# --- System services --- #
# Stops Svxlink, HealthCheck and this Python script
def force_stop():
    try:
        subprocess.run(["sudo", "systemctl", "stop", "svxlink"], check=True)
        subprocess.run(["sudo", "systemctl", "stop", "svxlink_healthcheck"], check=False) # optional script - depricated since 1.9.25
        subprocess.run(["sudo", "systemctl", "stop", "svxlink_healthcheck_python"], check=True)
        log_print("[SYSTEM] Svxlink, Healthcheck and Python script stopped by force.", GREEN)

        pid = os.getpid()
        os.kill(pid, signal.SIGKILL)

    except subprocess.CalledProcessError as e:
        log_print(f"[SYSTEM] Script encountered an error when stopping these scripts: {e}", RED)
        sys.exit(1)  

# Stops only Svxlink
def stop_svxlink():
    global wds_timer, tx_timer, squelch_timer, WDS_TIMEOUT, WDS_TIMEOUT_MAX
    try:
        # počistimo timerje, če obstajajo
        if wds_timer:
            wds_timer.cancel()
            wds_timer = None
            log_print("[INFO] WDS watchdog timer cancelled because service stopped.", BLUE)

        if tx_timer:
            tx_timer.cancel()
            tx_timer = None
            log_print("[INFO] TX timer cancelled because service stopped.", BLUE)

        if squelch_timer:
            squelch_timer.cancel()
            squelch_timer = None
            log_print("[INFO] Squelch timer cancelled because service stopped.", BLUE)
        if is_service_active("svxlink"):
            subprocess.run(["sudo", "systemctl", "stop", "svxlink"], check=True)
            log_print("[SYSTEM] Svxlink stopped by force.", GREEN)
            start_wds_timer()
            #log_print(f"[INFO] WDS watchdog timer started with {WDS_TIMEOUT}s", BLUE)
            return True
        else:
            #WDS_TIMEOUT = min(int(WDS_TIMEOUT * 1.2), WDS_TIMEOUT_MAX)
            log_print("[SYSTEM] Svxlink stop requested, but service is already inactive.", GREEN)
            start_wds_timer()
            return True
    except subprocess.CalledProcessError as e:
        log_print(f"[SYSTEM] Script encountered an error when stopping Svxlink by force: {e}", RED)
        log_print("[SYSTEM] Svxlink stopped by force.", GREEN)
        start_wds_timer()
        #log_print(f"[INFO] WDS watchdog timer started with {WDS_TIMEOUT}s", BLUE)
        return False

# Restarts a system service
def restart_service(service):
    global wds_timer, tx_timer, squelch_timer, failed_resets
    global RESET_TIMEOUT, WDS_TIMEOUT, MAX_FAILED_RESETS, WDS_TIMEOUT_MAX, WDS_TIMEOUT_INIT, keep_blocked

    try:
        if failed_resets >= MAX_FAILED_RESETS:
            log_print(f"[ALERT] Restart of 'svxlink' blocked. Too many failed attempts...({failed_resets})", RED)
            schedule_gmail(f"Svxlink has exceeded {MAX_FAILED_RESETS} failed resets! Stopping services.", force_send=True)
            time.sleep(5)
            force_stop()
            return False

        if keep_blocked and service == "svxlink":
            log_print(f"[ALERT] Restart of '{service}' is blocked by keep_blocked flag.", RED)
            return False

        if service == "svxlink":
            if wds_timer:
                wds_timer.cancel()
                log_print("[INFO] WDS timer cancelled because service restarted.", BLUE)
            if tx_timer:
                tx_timer.cancel()
                log_print("[INFO] TX timer cancelled because service restarted.", BLUE)
            if squelch_timer:
                squelch_timer.cancel()
                log_print("[INFO] RX timer cancelled because service restarted.", BLUE)

        try:
            subprocess.run(
                ["sudo", "systemctl", "restart", service],
                check=True,
                timeout=15
            )
        except subprocess.TimeoutExpired:
            log_print(f"[ALERT] Restart of '{service}' timed out after 15s! Retrying...", RED)
            failed_resets += 1
            return restart_service(service)  # recursive retry
        except subprocess.CalledProcessError as e:
            log_print(f"[SYSTEM] Error when restarting '{service}': {e}. Retrying...", RED)
            failed_resets += 1
            return restart_service(service)

        time.sleep(RESET_TIMEOUT)

        try:
            result = subprocess.run(
                ["systemctl", "is-active", service],
                capture_output=True,
                text=True,
                timeout=15
            )
            active = result.stdout.strip() == "active"
        except subprocess.TimeoutExpired:
            log_print(f"[ALERT] is_service_active('{service}') timed out after 15s! Retrying restart...", RED)
            failed_resets += 1
            return restart_service(service)

        if active:
            log_print(f"[SYSTEM] Service '{service}' restarted successfully.", GREEN)

            if service == "svxlink":
                failed_resets = 0
                WDS_TIMEOUT = WDS_TIMEOUT_INIT
                start_wds_timer()
            return True
        else:
            log_print(f"[SYSTEM] Service '{service}' restarted but crashed shortly after.", RED)

            if service == "svxlink":
                failed_resets += 1
                WDS_TIMEOUT = min(int(WDS_TIMEOUT * 1.2), WDS_TIMEOUT_MAX)
                start_wds_timer()
                log_print(
                    f"[INFO] WDS watchdog timer started with backoff and set to {WDS_TIMEOUT}s...({failed_resets})",
                    BLUE
                )
            return False

    except Exception as e:
        log_print(f"[SYSTEM] Unexpected error in restart_service('{service}'): {e}", RED)
        if service == "svxlink":
            failed_resets += 1
            WDS_TIMEOUT = min(int(WDS_TIMEOUT * 1.2), WDS_TIMEOUT_MAX)
            start_wds_timer()
            log_print(f"[INFO] WDS watchdog timer started with backoff and set to {WDS_TIMEOUT}s...({failed_resets})", BLUE)
        return False

# Returns bool status of systen service activity
def is_service_active(service):
    result = subprocess.run(["systemctl", "is-active", service], capture_output=True, text=True)
    return result.stdout.strip() == "active"
# --- End: System services --- #

# --- HealthCheck functions --- #
# Checks if svxlink froze on receive - resets AIOC and restarts svxlink upon detection
def check_freeze_rx():
    global squelch_open_time, squelch_timer, is_restarting, TIMEOUT_RX, failed_resets
    with lock:
        if squelch_open_time:
            elapsed = (datetime.now() - squelch_open_time).total_seconds()
            if elapsed >= TIMEOUT_RX and is_service_active("svxlink") and not is_restarting:
                error_str = f"[ALERT] svxlink may be frozen! (RX ON > {TIMEOUT_RX}s). Attempting a svxlink environment restart...({failed_resets})"
                log_print(error_str, RED)
                schedule_gmail(error_str, force_send=False)
                time.sleep(1)
                reset_aioc_with_restart()
            squelch_open_time = None
            squelch_timer = None

# Checks if svxlink froze on transmit - resets AIOC and restarts svxlink upon detection
def check_freeze_tx():
    global tx_on_time, tx_timer, is_restarting, TIMEOUT_TX, failed_resets
    with lock:
        if tx_on_time:
            elapsed = (datetime.now() - tx_on_time).total_seconds()
            if elapsed >= TIMEOUT_TX and is_service_active("svxlink") and not is_restarting:
                error_str = f"[ALERT] svxlink may be frozen! (TX ON > {TIMEOUT_TX}s). Attempting a svxlink environment restart...({failed_resets})"
                log_print(error_str, RED)
                schedule_gmail(error_str, force_send=False)
                time.sleep(1)
                reset_aioc_with_restart()
            tx_on_time = None
            tx_timer = None

# Checks for watchdog signal - restarts svxlink only
def check_wds_timeout():
    global wds_timer, WDS_TIMEOUT, failed_resets, WDS_TIMEOUT_MAX
    with lock:
        error_str = f"[ALERT] svxlink may be frozen! (No WDS signal for {WDS_TIMEOUT}s). Restarting svxlink service...({failed_resets})"
        log_print(error_str, RED)
        schedule_gmail(error_str, force_send=False)
        if wds_timer:
            try:
                wds_timer.cancel()
            except:
                pass
        wds_timer = None
        restart_service("svxlink")

# Starts WDS timer safely, without leaving some open
def start_wds_timer():
    global wds_timer, WDS_TIMEOUT
    if wds_timer:
        try:
            wds_timer.cancel()
            # debug
            #log_print("[INFO] Previous WDS timer cancelled before starting new.", BLUE)
        except Exception as e:
            log_print(f"[WARNING] Could not cancel previous WDS timer: {e}", YELLOW)
    wds_timer = threading.Timer(WDS_TIMEOUT, check_wds_timeout)
    wds_timer.daemon = True
    wds_timer.start()
    # debug
    log_print(f"[INFO] Timer: WDS watchdog timer (re)started with {WDS_TIMEOUT}s", BLUE)
# --- End: HealthCheck functions --- #
# --- End: Functions --- #

# --- Test --- #
def test():
    pass
# --- End: Test --- #


# --- Main function ---
def main():

    # If needed... just call functions inside test
    #test()

    get_sql_timeout()
    get_timeout()
    get_wds_signal_interval()
    time.sleep(1)

    log_print("[SYSTEM] Svxlink monitoring activated ...", GREEN)

    restart_service("svxlink")

    global event_handler
    event_handler = LogHandler()
    observer = Observer()
    observer.schedule(event_handler, path="/var/log", recursive=False)
    observer.start()
    threading.Thread(target=periodic_email_sender, daemon=True).start()

    try:
        while True:
            time.sleep(1)  
    except KeyboardInterrupt:
        observer.stop()
    observer.join()

if __name__ == "__main__":
    main()

