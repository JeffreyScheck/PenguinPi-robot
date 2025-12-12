#!/bin/bash

# Run this script with sudo!!!
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

########################################################################################
echo "Removing old hotspot configurations..."

HOTSPOTS=$(nmcli -t -f NAME connection show | grep -i "hotspot")
for hs in $HOTSPOTS; do
    echo "Deleting hotspot connection: $hs"
    nmcli connection delete "$hs"
done

nmcli connection delete "RVSS_Starlink"
nmcli connection delete "EGB439"


########################################################################################
# Hostapd Configuration
echo "Setting up hotspot configuration in hostapd"

MAC=$(cat /sys/class/net/wlan0/address)
sudo echo "
#2.4GHz setup wifi 80211 b,g,n
interface=wlan0
driver=nl80211
ssid=penguinpi:${MAC: -8}
hw_mode=g
channel=8
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=egb439123
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP TKIP
rsn_pairwise=CCMP

#80211n -
country_code=AU
ieee80211n=1
ieee80211d=1
" > /etc/hostapd/hostapd.conf

########################################################################################
# Replace wpa_supplicant.conf with the template file
sudo mv /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf.backup # Backup old file
sudo cp wpa_supplicant_default.conf /etc/wpa_supplicant/wpa_supplicant.conf


########################################################################################
# Starlink configuration
nmcli connection add type wifi ifname wlan0 con-name RVSS_Starlink ssid RVSS_Starlink
nmcli connection modify RVSS_Starlink \
    wifi-sec.key-mgmt wpa-psk \
    wifi-sec.psk "RVSS2026" \
    connection.autoconnect yes \
    connection.autoconnect-priority 10 \
    ipv4.method auto \
    ipv6.method auto

########################################################################################
# Starlink configuration
nmcli connection add type wifi ifname wlan0 con-name EGB439 ssid EGB439
nmcli connection modify EGB439 \
    wifi-sec.key-mgmt wpa-psk \
    wifi-sec.psk "egb439123" \
    connection.autoconnect yes \
    connection.autoconnect-priority 10 \
    ipv4.method auto \
    ipv6.method auto

########################################################################################
# Hotspot configuration
nmcli device wifi hotspot ssid penguinpi:${MAC: -8} password PenguinPi ifname wlan0
hotspotUUID="$(nmcli --get-values connection.uuid c show Hotspot)"
sudo nmcli connection modify $hotspotUUID connection.autoconnect yes connection.autoconnect-priority -10


########################################################################################
echo "Done! Reboot is required"
exit 0
