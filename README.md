# Embedded_WiFi_Gateway
A high compatibility WiFi Access Point &amp; IoT Gateway for Raspberry Pi 3B, optimized for modern mobile clients.

## IoT Gateway & WiFi Access Point (RPi 3B)
A robust, "zero-touch" IoT Gateway designed to bridge Ethernet internet to a localized WiFi mesh of ESP32 edge nodes. This project specifically optimizes the Broadcom BCM43438 wireless stack to support modern high-security clients (iOS 19+, Android 16+, macOS) on legacy hardware.

## 🚀 Features
* **Modern Stack:** Native `NetworkManager` integration (No legacy `hostapd` conflicts).
* **Hardware-Tuned:** Optimized 802.11 stack to resolve **"Authentication Timeout"** and **"Incorrect Password"** errors.
* **Persistent Fixes:** Automated hardware power-management stabilization on boot via `crontab`.
* **Global Ready:** Pre-configured for **Germany (DE)** regulatory domains.

---

## ⚠️ Important Warnings
* **Ethernet Required:** Your Raspberry Pi **must** be connected to the internet via an **Ethernet cable** to share internet access via the hotspot.
* **Connection Drop:** **Do not** run the setup script while connected to the Pi via WiFi. You will lose your connection. Use an **Ethernet SSH** or **Serial Console** connection.
* **Sudo Privileges:** This script modifies system networking files and requires **`sudo`** permissions.

---

## 🛠️ Regional Configuration (Germany)
Since this project was developed at **TU Chemnitz**, it is configured for the German regulatory domain. This ensures the WiFi radio operates on legal frequencies and power levels for the EU.

To verify or change your country code manually:
```bash
sudo raspi-config nonint do_wifi_country DE
```

# 🛠️ Technical Challenges & Solutions
1. The "Incorrect Password" Paradox

Issue: Modern Apple and Android devices reported "Incorrect Password" or "Timeout" despite correct credentials.
Root Cause: The RPi 3B's WiFi chip power-management caused latency spikes during the cryptographic 4-way handshake, exceeding the strict timing windows of modern mobile OSs.
Solution: Hard-coded power_save off at the kernel level via iw and crontab to ensure 100% radio readiness.

2. SHA-1 Deprecation & GPG Security

Issue: Standard apt update failed due to the 2026 deprecation of SHA-1 signatures in third-party repositories (NodeSource/RaspAP).
Solution: Manually migrated repository trust to the signed-by /usr/share/keyrings/ architecture using Sequoia-PGP compliant keys.

# 📦 Installation
Prerequisites

Raspberry Pi 3 Model B (or newer)

Raspberry Pi OS (64-bit preferred)

Ethernet connection (for internet sharing)

One-Step Setup

Clone the repository and run the setup script:

```Bash
git clone https://github.com/YourUsername/RPi-IoT-Gateway.git
cd WiFi_Embedded_Gateway
chmod +x setup_hotspot.sh
sudo ./setup_hotspot.sh
```

# ⚙️ Configuration
The default settings can be modified in setup_hotspot.sh:

SSID: EmbeddedWifiGateway

Password: EnterThePortal@26

Gateway IP: 192.168.8.1

### 🔍 Technical Deep-Dive: Resolving Handshake Timeouts
During development, we identified that modern iOS and macOS devices often fail to connect to the RPi 3B, reporting an "Incorrect Password" error.

The Solution implemented in this script:

**Disable PMF:** Set 802-11-wireless-security.pmf to 1 (Disabled/Optional). Older Broadcom firmware fails the 802.11w encrypted management frame handshake.

**Disable Power Save:** Forced iw dev wlan0 set power_save off via crontab at boot. This prevents the WiFi chip from "napping" during the high-speed 4-way cryptographic handshake.

## 📊 Monitoring Connections
To see connected devices in real-time, run:

```bash
nmcli device wifi list --rescan yes
```

## Future Scope & Roadmap

This gateway is the foundation for a larger IoT ecosystem. Planned future developments include:

* **MQTT Broker Integration:** Deploying a Mosquitto broker on the Pi to handle telemetry data from ESP32 edge nodes.
* **Web Dashboard:** Developing a lightweight Flask or Node.js dashboard to monitor connected device health and signal strength.
* **OTA Updates:** Implementing Over-The-Air (OTA) update capabilities for connected ESP32 clients via the RPi gateway.

## 📜 License
Distributed under the MIT License. See LICENSE for more information.
