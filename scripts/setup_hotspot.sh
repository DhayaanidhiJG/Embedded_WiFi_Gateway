#!/bin/bash

# =================================================================
# PROJECT: Embedded WiFi Gateway Setup
# AUTHOR: Dhayaanidhi Jagadesan Govindharaju
# DESCRIPTION: High-compatibility AP for RPi 3B (Broadcom BCM43438)
# =================================================================

# --- Configuration ---
SSID="EmbeddedWifiGateway"
PASSWORD="EnterThePortal@26"
GATEWAY_IP="192.168.8.1/24"
INTERFACE="wlan0"

# Terminal Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}>>> Initializing Embedded WiFi IoT Gateway Setup...${NC}"

# 1. FIX REPOSITORY GPG ISSUES
echo -e "${GREEN}[1/7] Updating system keys...${NC}"
sudo apt-get update || {
    echo -e "${RED}GPG Error detected. Updating archive keyring...${NC}"
    sudo apt-get install -y raspberrypi-archive-keyring
    sudo apt-get update
}

# 2. CLEANUP LEGACY SERVICES
echo -e "${GREEN}[2/7] Purging conflicting services (hostapd/dnsmasq)...${NC}"
sudo systemctl stop hostapd dnsmasq 2>/dev/null
sudo systemctl mask hostapd dnsmasq 2>/dev/null
sudo apt purge -y hostapd dnsmasq -qq

# 3. CREATE NETWORKMANAGER PROFILE
echo -e "${GREEN}[3/7] Creating Hotspot profile: $SSID...${NC}"
sudo nmcli connection delete "$SSID" 2>/dev/null
sudo nmcli device wifi hotspot ssid "$SSID" password "$PASSWORD" ifname "$INTERFACE"

# 4. HARDWARE COMPATIBILITY PATCHES (The Apple/Android Fix)
echo -e "${GREEN}[4/7] Applying 802.11 stack tuning...${NC}"
# Disable PMF (Protected Management Frames) for legacy firmware support
sudo nmcli connection modify "$SSID" 802-11-wireless-security.pmf 1
# Force WPA2-AES (CCMP)
sudo nmcli connection modify "$SSID" 802-11-wireless-security.proto rsn
sudo nmcli connection modify "$SSID" 802-11-wireless-security.group ccmp
sudo nmcli connection modify "$SSID" 802-11-wireless-security.pairwise ccmp
# Disable NetworkManager's internal power save
sudo nmcli connection modify "$SSID" 802-11-wireless.powersave 2

# 5. CONFIGURE NETWORKING & DHCP
echo -e "${GREEN}[5/7] Configuring Gateway IP and NAT Sharing...${NC}"
sudo nmcli connection modify "$SSID" ipv4.addresses "$GATEWAY_IP" ipv4.method shared
sudo nmcli connection modify "$SSID" connection.autoconnect yes

# 6. PERSISTENT POWER FIX (Crontab)
echo -e "${GREEN}[6/7] Setting up persistent hardware override...${NC}"
FIX_SCRIPT="/usr/local/bin/disable-wifi-powersave.sh"
echo -e "#!/bin/bash\n/usr/sbin/iw dev $INTERFACE set power_save off" | sudo tee $FIX_SCRIPT > /dev/null
sudo chmod +x $FIX_SCRIPT

# Ensure it runs on every boot
(sudo crontab -l 2>/dev/null | grep -q "$FIX_SCRIPT") || \
(sudo crontab -l 2>/dev/null; echo "@reboot $FIX_SCRIPT") | sudo crontab -

# 7. ACTIVATION
echo -e "${GREEN}[7/7] Starting the Access Point...${NC}"
sudo /usr/sbin/iw dev "$INTERFACE" set power_save off  # Immediate hardware override
sudo nmcli connection up "$SSID"

echo -e "${CYAN}====================================================${NC}"
echo -e "${GREEN} SETUP SUCCESSFUL!${NC}"
echo -e " SSID:     $SSID"
echo -e " PASSWORD: $PASSWORD"
echo -e " GATEWAY:  192.168.8.1"
# echo -e " REGION:   DE (Germany)"
echo -e "${CYAN}====================================================${NC}"
