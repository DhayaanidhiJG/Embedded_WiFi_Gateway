### Troubleshooting & Technical Deep-Dive
This document outlines the specific hardware and software challenges encountered during the development of the Embedded WiFi Gateway and the engineered solutions applied.

## 1. iPhone/MacBook "Incorrect Password" Loop
***Symptom***: Modern Apple devices (iOS 18/19+, macOS) repeatedly prompt for a password or report "Incorrect Password" even when credentials are correct.

***Technical Root Cause***: * PMF (Protected Management Frames): Modern devices require 802.11w. The Broadcom BCM43438 chip on the RPi 3B has limited support for this in its firmware. When the handshake begins, the timing window for management frame encryption is missed.

***Handshake Latency:*** By default, the RPi 3B uses aggressive power management to save energy. This introduces a ~10-20ms wake-up latency. Modern devices expect the 4-way handshake to complete within a very tight window; if the Pi responds too slowly, the device assumes a cryptographic mismatch (Incorrect Password).

***The Fix:***

Force disable PMF in nmcli.

Explicitly disable hardware power saving using iw dev wlan0 set power_save off.

## 2. "802.1X supplicant took too long to authenticate"
***Symptom:*** The command nmcli connection up fails with a timeout error.

![Supplicant Timeout Error](docs/ErrorLog.png)

***Technical Root Cause:*** This is a race condition between NetworkManager and the underlying wpa_supplicant. On the RPi 3B's slower CPU, the default 10-second timeout for the supplicant to initialize the Access Point (AP) mode is sometimes exceeded if the system is under load or if legacy configuration files (like hostapd) are still partially active.

***The Fix:***

The setup script masks and purges hostapd and dnsmasq to ensure NetworkManager has exclusive control over the wireless stack.

We use a "Create-then-Modify" approach in the script to ensure all parameters are set before the interface is brought up.

## 3. GPG / SHA-1 Repository Errors (2026 Deprecation)
***Symptom:*** sudo apt update fails with "Signature verification error" or "The following signatures were invalid."

***Technical Root Cause:*** As of 2026, Debian-based systems (like Raspberry Pi OS) have fully deprecated the use of SHA-1 for repository signing. Older setup guides often point to repositories using legacy keys.

***The Fix:***

Manually imported the latest Sequoia-PGP compliant keys.

Updated the source list to use the signed-by parameter, pointing directly to the /usr/share/keyrings/ directory to bypass legacy keyring issues.

## 4. WiFi Regulatory Domain (DE)
***Symptom:*** Hotspot is visible but devices refuse to connect, or the SSID is not visible at all.

***Technical Root Cause:*** WiFi channels 12 and 13 are legal in Germany but illegal in the US. If the Pi is set to a "Global" or "US" domain while in Chemnitz, it may try to use a channel that the device (configured for Germany) rejects, or vice versa.

***The Fix:***

The script forces the regulatory domain to DE.

We pin the frequency to the 2.4GHz band (bg), as the RPi 3B does not support 5GHz.