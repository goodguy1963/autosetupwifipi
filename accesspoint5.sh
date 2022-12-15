#!/bin/bash

#check if device has internet connection
if ! ping -c 1 google.com &> /dev/null
then
#if no connection, turn pi into a wireless access point
sudo apt-get update
sudo apt-get install hostapd dnsmasq
sudo systemctl stop hostapd
sudo systemctl stop dnsmasq

#configure access point settings
sudo sed -i 's/^#DAEMON_CONF=""/DAEMON_CONF="/etc/hostapd/hostapd.conf"/g' /etc/default/hostapd
sudo echo "interface wlan0
static ip_address=192.168.4.1/24
nohook wpa_supplicant" >> /etc/dhcpcd.conf
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
sudo echo "interface=wlan0
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h" >> /etc/dnsmasq.conf

#configure access point name and password
sudo echo "interface=wlan0
driver=nl80211
ssid=SETUP PI
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0" >> /etc/hostapd/hostapd.conf

#restart services
sudo systemctl start hostapd
sudo systemctl start dnsmasq

#enable ipv4 forwarding
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
sudo sed -i '$ i\iptables-restore < /etc/iptables.ipv4.nat' /etc/rc.local

#install and configure GUI for wifi credentials
sudo apt-get install lighttpd php7.3-cgi
sudo lighty-enable-mod fastcgi fastcgi-php
sudo systemctl restart lighttpd
sudo cp /usr/local/src/Wifi-Setup-Webpage/wifi_setup.php /var/www/html
sudo cp /usr/local/src/Wifi-Setup-Webpage/wifi_setup.css /var/www/html

#notify user when connection is established
sudo sed -i '$ i\notify-send "Connection Established!"' /etc/rc.local
fi

exit 0
