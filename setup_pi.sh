#!/bin/bash
#Installation Dependencies
apt-get install dnsmasq hostapd apache2

#Check for internet connection
if ! ping -c 1 google.com > /dev/null 2>&1; then
# Display message on HDMI output
echo "Connect to the 'SETUP PI - Network' to enter WIFI credentials"
else
exit 0
fi

#Create access point with hostapd
cat > /etc/hostapd/hostapd.conf <<EOF
interface=wlan0
driver=nl80211
ssid=SETUP PI
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=12345678
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF

#Configure DHCP server with dnsmasq
cat > /etc/dnsmasq.conf <<EOF
interface=wlan0
dhcp-range=10.0.0.2,10.0.0.5,255.255.255.0,12h
dhcp-option=3,10.0.0.1
dhcp-option=6,10.0.0.1
EOF

#Enable IP forwarding and NAT
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

#Start services
service hostapd start
service dnsmasq start

#Create web server with GUI for wifi credentials
cat > /var/www/html/index.html <<EOF

<html>
<head>
<title>SETUP PI WIFI Configuration</title>
</head>
<body>
<h1>SETUP PI WIFI Configuration</h1>
<form action="wifi.php" method="post">
<h3>WIFI Credentials</h3>
SSID: <input type="text" name="ssid"><br>
Password: <input type="password" name="password"><br>
Security:
<input type="radio" name="security" value="wpa"> WPA
<input type="radio" name="security" value="wpa2"> WPA2
<input type="radio" name="security" value="wep"> WEP
<input type="radio" name="security" value="eap"> EAP<br>
<h3>WIFI Static Configuration (Optional)</h3>
IP Address: <input type="text" name="wifi_ip"><br>
Netmask: <input type="text" name="wifi_netmask"><br>
Gateway: <input type="text" name="wifi_gateway"><br>
DNS: <input type="text" name="wifi_dns"><br>
Secondary DNS: <input type="text" name="wifi_dns2"><br>
<h3>LAN Static Configuration (Optional)</h3>
IP Address: <input type="text" name="lan_ip"><br>
Netmask: <input type="text" name="lan_netmask"><br>

Gateway: <input type="text" name="lan_gateway"><br>
DNS: <input type="text" name="lan_dns"><br>
Secondary DNS: <input type="text" name="lan_dns2"><br>

<h3>Proxy Configuration (Optional)</h3>
Proxy Type:
<input type="radio" name="proxy_type" value="http"> HTTP
<input type="radio" name="proxy_type" value="https"> HTTPS<br>
Proxy Server: <input type="text" name="proxy_server"><br>
Port: <input type="text" name="proxy_port"><br>
Username: <input type="text" name="proxy_username"><br>
Password: <input type="password" name="proxy_password"><br>
Proxy Exceptions: <input type="text" name="proxy_exceptions"><br>
<input type="submit" value="Submit">
</form>
</body>
</html>
EOF
cat > /var/www/html/wifi.php <<EOF

<?php
\$ssid = \$_POST["ssid"];
\$password = \$_POST["password"];
\$security = \$_POST["security"];
\$wifi_ip = \$_POST["wifi_ip"];
\$wifi_netmask = \$_POST["wifi_netmask"];
\$wifi_gateway = \$_POST["wifi_gateway"];
\$wifi_dns = \$_POST["wifi_dns"];
\$wifi_dns2 = \$_POST["wifi_dns2"];
\$lan_ip = \$_POST["lan_ip"];
\$lan_netmask = \$_POST["lan_netmask"];
\$lan_gateway = \$_POST["lan_gateway"];
\$lan_dns = \$_POST["lan_dns"];
\$lan_dns2 = \$_POST["lan_dns2"];
\$proxy_type = \$_POST["proxy_type"];
\$proxy_server = \$_POST["proxy_server"];
\$proxy_port = \$_POST["proxy_port"];
\$proxy_username = \$_POST["proxy_username"];
\$proxy_password = \$_POST["proxy_password"];
\$proxy_exceptions = \$_POST["proxy_exceptions"];

\$wpa_str = "";
if (\$security == "wpa") {
    \$wpa_str = "wpa=1\nwpa_passphrase=\$password\n";
} elseif (\$security == "wpa2") {
    \$wpa_str = "wpa=2\nwpa_passphrase=\$password\n";
} elseif (\$security == "wep") {
    \$wpa_str = "wep_key0=\$password\n";
} elseif (\$security == "eap") {
    \$wpa_str = "ieee8021x=1\nauth_server_addr=127.0.


0.1\nauth_server_port=1812\nauth_server_shared_secret=testing123\n";
}

$wifi_static_str = "";
if ($wifi_ip && $wifi_netmask && $wifi_gateway && $wifi_dns && $wifi_dns2) {
$wifi_static_str = "static ip_address=$wifi_ip/$wifi_netmask\n gateway=$wifi_gateway\n dns-nameservers $wifi_dns $wifi_dns2\n";
}

$lan_static_str = "";
if ($lan_ip && $lan_netmask && $lan_gateway && $lan_dns && $lan_dns2) {
$lan_static_str = "iface eth0 inet static\n address $lan_ip\n netmask $lan_netmask\n gateway $lan_gateway\n dns-nameservers $lan_dns $lan_dns2\n";
}

$proxy_str = "";
if ($proxy_type && $proxy_server && $proxy_port && $proxy_username && $proxy_password && $proxy_exceptions) {
$proxy_str = "Acquire::$proxy_type::proxy "http://$proxy_username:$proxy_password@$proxy_server:$proxy_port/";\n Acquire::$proxy_type::proxy "https://$proxy_username:$proxy_password@$proxy_server:$proxy_port/";\n Acquire::$proxy_type::proxy::$proxy_exceptions "DIRECT";\n";
}

$wpa_conf = <<<EOT
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
ssid="$ssid"
$wpa_str
}
EOT;

file_put_contents("/etc/wpa_supplicant/wpa_supplicant.conf", $wpa_conf);

$interfaces = <<<EOT
auto lo
iface lo inet loopback

auto eth0
$lan_static_str

auto wlan0
$wifi_static_str
allow-hotplug wlan0
iface wlan0 inet dhcp
wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
EOT;

file_put_contents("/etc/network/interfaces", $interfaces);

$apt_conf = <<<EOT
$proxy_str
EOT;

file_put_contents("/etc/apt/apt.conf", $apt_conf);

echo "WIFI configuration successfully applied. Please reboot the device to apply changes.";
EOF

#Add script to run on boot
echo "@reboot /bin/bash /root/setup_pi.

sh" >> /etc/crontab

#Run script after boot
/bin/bash /root/setup_pi.sh

echo "Setup PI configuration complete. Please connect to the 'SETUP PI - Network' access point and navigate to 'setup.pi' to enter your wifi credentials."



