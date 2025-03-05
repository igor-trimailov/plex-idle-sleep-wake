# Plex Server Idle Inhibition & Wake-on-LAN (WOL) Workaround

This repository contains tools to prevent your Ubuntu server from suspending while Plex is actively streaming and to ensure that the Wake-on-LAN (WOL) setting is properly re-applied after a resume.

The solution consists of three parts:

1.  **Plex Inhibition Script (plex_inhibit.sh):**

    A Bash script that queries the Plex API for active streaming sessions. If a stream is active, it prevents the system from suspending by holding a systemd inhibitor lock.

2.  **Cron Job Setup:**

    A cron entry that runs the Plex inhibition script periodically (every 15 minutes) to keep the system awake while Plex is in use.

3.  **NetworkManager Dispatcher Script:**

    A dispatcher script that automatically re-applies the WOL setting when the network interface is brought up after suspend—this is necessary because NetworkManager often resets NIC settings during resume.

## Disclaimer

The scripts and instructions provided here are offered "as is" without warranty of any kind. I am not a certified expert, and I assume no responsibility for any damage, data loss, or other issues that may occur from using these scripts. Please test in a safe environment before deploying to production.

## Prerequisites

Before using these scripts, ensure your system meets the following prerequisites:
1. **Ubuntu Version:**
  Ensure you're running a supported Ubuntu release (e.g., Ubuntu 22.04 LTS) with systemd.
2. **Required Tools:**
Install the necessary tools with:
    ```bash
    sudo apt update
    sudo apt install ethtool wakeonlan jq curl
    ```
3. **Suspend Settings:**
Configure your system to suspend on idle. For example, edit `/etc/systemd/logind.conf`:
    ```ini
    IdleAction=suspend
    IdleActionSec=1800
    ```

    Then restart systemd-logind:
    ```bash
    sudo systemctl restart systemd-logind
    ```

4. **BIOS/UEFI Configuration:**
    Enable Wake-on-LAN (WOL) in your BIOS/UEFI settings.
5. **Network Interface:**
    Verify that your network interface (e.g., `eno1`) supports WOL and note its MAC address.
6. **Wake-on-LAN phone app**: 
    Android/IOS app that can wake up the server using MAC address.

## 1. Plex Inhibition Script

File: `plex_inhibit.sh`

This script checks if there are any active Plex streams by querying the Plex sessions API. If active streams are detected, it uses `systemd-inhibit` to block idle suspend for 30 minutes.

### Testing the script

1. Make it executable
   ```bash
   chmod +x plex_inhibit.sh
   ```
2. Run script manually
   ```bash
   ./plex_inhibit.sh
   ```
3. Check the logs
   ```bash
   sudo journalctl -t plex_inhibit -r
   ```

## 2. Cron job setup

To ensure the script runs regularly (every 15 minutes), add the following line to your user or system crontab:

1. Open crontab editor:
   ```bash
   crontab -e
   ```
2. Add this line, replacing `/path/to/plex_inhibit.sh` with the actual path:
   ```bash
   */15 * * * * /path/to/plex_inhibit.sh >> /var/log/plex_inhibit.log 2>&1
   ```

### Explanation

- `*/15 * * * *`: Runs the script every 15 minutes.
- `/path/to/plex_inhibit.sh`: Full path to your script.
- `>> /var/log/plex_inhibit.log 2>&1`: Appends both standard output and errors to /var/log/plex_inhibit.log (ensure this file is writable or change the path to a location with proper permissions).

## 3. NetworkManager Dispatcher Script

If your system resets the WOL setting after resume, use a NetworkManager dispatcher script to reapply it when the interface comes up.

File: `99-wol`

1. Create dispatcher file for wol:
   ```bash
   sudo touch /etc/NetworkManager/dispatcher.d/99-wol
   ```
2. Make it executable:
   ```bash
   sudo chmod +x /etc/NetworkManager/dispatcher.d/99-wol
   ```

### How It Works

- The dispatcher script is triggered automatically by NetworkManager whenever the state of an interface changes.
- It checks if the interface is correct and that its new state is up. If so, it uses ethtool to set the WOL setting (using wol ug to allow both magic packet and unicast wake).
- A log entry is created using logger with the tag wol_dispatcher.

## Summary

- **Plex Inhibition Script (plex_inhibit.sh):**

  Prevents suspend if Plex is streaming.

- **Cron Job:**

  Runs the inhibition script every 15 minutes.

- **NetworkManager Dispatcher Script:**

  Reapplies the WOL setting after the network interface comes up following a suspend.
