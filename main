#!/usr/bin/env bash

#Install required packages
apt-get update
apt-get install -y hostapd dnsmasq

#Configure hostapd
cat > /etc/hostapd/hostapd.conf <<EOF
interface=wlan0
driver=nl80211
ssid=SETUP_PI
hw_mode=g
channel=6
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
EOF

#Configure dnsmasq
cat > /etc/dnsmasq.conf <<EOF
interface=wlan0
listen-address=192.168.50.1
bind-interfaces
server=8.8.8.8
domain-needed
bogus-priv
dhcp-range=192.168.50.50,192.168.50.150,12h
EOF

#Update configuration files to use hostapd
sed -i 's/#DAEMON_CONF=""/DAEMON_CONF="/etc/hostapd/hostapd.conf"/g' /etc/default/hostapd
sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

#Set up NAT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT

#Save iptables rules
sh -c "iptables-save > /etc/iptables.ipv4.nat"

#Update rc.local to restore iptables rules on boot
sed -i -e '$i \iptables-restore < /etc/iptables.ipv4.nat\n' /etc/rc.local

#Start services
systemctl unmask hostapd
systemctl enable hostapd
systemctl start hostapd
systemctl enable dnsmasq
systemctl start dnsmasq

#Create local webpage for wifi setup
cat > /var/www/html/index.html <<EOF

<html>
<head>
<title>SETUP PI</title>
</head>
<body>
<h1>SETUP PI</h1>
<p>Please enter your wifi credentials to connect to your network:</p>
<form action="setup.php" method="post">
SSID:<br>
<input type="text" name="ssid"><br>
Password:<br>
<input type="password" name="password"><br><br>
<input type="submit" value="Submit">
</form>
</body>
</html>
EOF
#Create PHP script for wifi setup
cat > /var/www/html/setup.php <<EOF

<?php
\$ssid = \$_POST["ssid"];
\$password = \$_POST["password"];

\$wpa_supplicant_conf = <<<EOD
ctrl_interface=DIR=/var


