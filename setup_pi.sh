#!/bin/bash

#Installation Dependencies
apt-get install dnsmasq hostapd apache2

#Check internet connection
if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
echo "ALREADY CONNECTED"

#Add script to run on boot
cp setup_pi.sh /etc/rc.local

#Add script to run after boot
cp setup_pi.sh /etc/init.d/
else

#Display message on Raspberry Pi HDMI Output
echo "Connect to the 'SETUP PI - Network' to enter WIFI credentials"

#Turn into wireless access point
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

#Configure DHCP server
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
fi

#Create locally hosted web server
a2enmod cgid
else
 {a2enmod cgi}
service apache2 start

#Create GUI for wifi credentials
cat <<EOF > /var/www/setup.pi/index.html

<html>
  <head>
    <title>SETUP PI Wifi Configuration</title>
  </head>
  <body>
    <h1>SETUP PI Wifi Configuration</h1>
    <form action="wifi-config.cgi" method="post">
      <label for="ssid">SSID:</label><br>
      <input type="text" id="ssid" name="ssid"><br>
      <label for="psk">Password:</label><br>
      <input type="password" id="psk" name="psk"><br>
      <label for="encryption">Encryption:</label><br>
      <select id="encryption" name="encryption">
        <option value="wpa">WPA</option>
        <option value="wep">WEP</option>
        <option value="wpa2">WPA2</option>
        <option value="eap">EAP</option>
      </select><br>
      <input type="checkbox" id="proxy" name="proxy" value="yes">
      <label for="proxy">Use proxy:</label><br>
      <div id="proxy-fields" style="display:none;">
        <label for="proxy-host">Proxy Host:</label><br>
        <input type="text" id="proxy-host" name="proxy-host"><br>
        <label for="proxy-port">Proxy Port:</label><br>
        <input type="text" id="proxy-port" name="proxy-port"><br>
        <label for="proxy-username">Proxy Username:</label><br>
        <input type="text" id="proxy-username" name="proxy-username"><br>
        <label for="proxy-password">Proxy Password:</label><br>
        <input type="password" id="proxy-password" name="proxy-password"><br>
        <label for="proxyexceptions">Proxy Exceptions:</label><br>
<input type="text" id="proxy-exceptions" name="proxy-exceptions"><br>
</div>
<input type="checkbox" id="wifi-static" name="wifi-static" value="yes">
<label for="wifi-static">Use static wifi configuration:</label><br>
<div id="wifi-static-fields" style="display:none;">
<label for="wifi-ip">IP Address:</label><br>
<input type="text" id="wifi-ip" name="wifi-ip"><br>
<label for="wifi-netmask">Netmask:</label><br>
<input type="text" id="wifi-netmask" name="wifi-netmask"><br>
<label for="wifi-gateway">Gateway:</label><br>
<input type="text" id="wifi-gateway" name="wifi-gateway"><br>
<label for="wifi-dns">DNS:</label><br>
<input type="text" id="wifi-dns" name="wifi-dns"><br>
<label for="wifi-secondary-dns">Secondary DNS:</label><br>
<input type="text" id="wifi-secondary-dns" name="wifi-secondary-dns"><br>
</div>
<input type="checkbox" id="lan-static" name="lan-static" value="yes">
<label for="lan-static">Use static LAN configuration:</label><br>
<div id="lan-static-fields" style="display:none;">
<label for="lan-ip">IP Address:</label><br>
<input type="text" id="lan-ip" name="lan-ip"><br>
<label for="lan-netmask">Netmask:</label><br>
<input type="text" id="lan-netmask" name="lan-netmask"><br>
<label for="lan-gateway">Gateway:</label><br>
<input type="text" id="lan-gateway" name="lan-gateway"><br>
<label for="lan-dns">DNS:</label><br>
<input type="text" id="lan-dns" name="lan-dns"><br>
<label for="lan-secondary-dns">Secondary DNS:</label><br>
<input type="text" id="lan-secondary-dns" name="lan-secondary-dns"><br>
</div>
<input type="submit" value="Submit">
</form>

  </body>
</html>
EOF
#Create CGI script for wifi configuration
cat <<EOF > /var/www/setup.pi/wifi-config.cgi
#!/bin/bash
echo "Content-type: text/html"
echo ""
echo "<html><head><title>SETUP PI Wifi Configuration</title></head><body>"

#Read wifi configuration
SSID=$(cat /var/www/setup.pi/wifi-config | grep ssid | cut -d '=' -f 2)
PSK=$(cat /var/www/setup.pi/wifi-config | grep psk | cut -d '=' -f 2)
ENCRYPTION=$(cat /var/www/setup.pi/wifi-config | grep encryption | cut -d '=' -f 2)

#Check if proxy is enabled
if [ "$(cat /var/www/setup.pi/wifi-config | grep proxy | cut -d '=' -f 2)" == "yes" ]; then
PROXY_HOST=$(cat /var/www/setup.pi/wifi-config | grep proxy-host | cut -d '=' -f 2)
PROXY_PORT=$(cat /var/www/setup.pi/wifi-config | grep proxy-port | cut -d '=' -f 2)
PROXY_USERNAME=$(cat /var/www/setup.pi/wifi-config | grep proxy-username | cut -d '=' -f 2)
PROXY_PASSWORD=$(cat /var/www/setup.pi/wifi-config | grep proxy-password | cut -d '=' -f 2)
PROXY_EXCEPTIONS=$(cat /var/www/setup.pi/wifi-config | grep proxy-exceptions | cut -d '=' -f 2)

#Set up proxy
cat <<EOF > /etc/environment
http_proxy="http://$PROXY_USERNAME:$PROXY_PASSWORD@$PROXY_HOST:$PROXY_PORT"
https_proxy="https://$PROXY_USERNAME:$PROXY_PASSWORD@$PROXY_HOST:$PROXY_PORT"
ftp_proxy="ftp://$PROXY_USERNAME:$PROXY_PASSWORD@$PROXY_HOST:$PROXY_PORT"
no_proxy="localhost,127.0.0.1,$PROXY_EXCEPTIONS"

fi

#Check if wifi static configuration is enabled
if [ "$(cat /var/www/setup.pi/wifi-config | grep wifi-static | cut -d '=' -f 2)" == "yes" ]; then
WIFI_IP=$(cat /var/www/setup.pi/wifi-config | grep wifi-ip | cut -d '=' -f 2)
WIFI_NETMASK=$(cat /var/www/setup.pi/wifi-config | grep wifi-netmask | cut -d '=' -f 2)
WIFI_GATEWAY=$(cat /var/www/setup.pi/wifi-config | grep wifi-gateway | cut -d '=' -f 2)
WIFI_DNS=$(cat /var/www/setup.pi/wifi-config | grep wifi-dns | cut -d '=' -f 2)
WIFI_SECONDARY_DNS=$(cat /var/www/setup.pi/wifi-config | grep wifi-secondary-dns | cut -d '=' -f 2)
EOF
#Set up wifi static configuration
cat <<EOF > /etc/network/interfaces.d/wlan0
auto wlan0
iface wlan0 inet static
address $WIFI_IP
netmask $WIFI_NETMASK
gateway $WIFI_GATEWAY
dns-nameservers $WIFI_DNS $WIFI_SECONDARY_DNS
EOF
fi

#Check if LAN static configuration is enabled
if [ "$(cat /var/www/setup.pi/wifi-config | grep lan-static | cut -d '=' -f 2)" == "yes" ]; then
LAN_IP=$(cat /var/www/setup.pi/wifi-config | grep lan-ip | cut -d '=' -f 2)
LAN_NETMASK=$(cat /var/www/setup.pi/wifi-config | grep lan-netmask | cut -d '=' -f 2)
LAN_GATEWAY=$(cat /var/www/setup.pi/wifi-config | grep lan-gateway | cut -d '=' -f 2)
LAN_DNS=$(cat /var/www/setup.pi/wifi-config | grep lan-dns | cut -d '=' -f 2)
LAN_SECONDARY_DNS=$(cat /var/www/setup.pi/wifi-config | grep lan-secondary-dns | cut -d '=' -f 2)

#Set up LAN static configuration
cat <<EOF > /etc/network/interfaces.d/eth0
auto eth0
iface eth0 inet static
address $LAN_IP
netmask $LAN_NETMASK
gateway $LAN_GATEWAY
dns-nameservers $LAN_DNS $LAN_SECONDARY_DNS
EOF
fi

#Set up wifi connection
cat <<EOF > /etc/wpa_supplicant/wpa_supplicant.conf
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

network={
ssid="$SSID"
psk="$PSK"
key_mgmt=$ENCRYPTION
}
EOF

#Restart networking service
service networking restart

#Check if wifi connection is successful
if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
echo "<h2>Connection successful!</h2>"
else
echo "<h2>Connection failed. Please try again.</h2>"
fi

echo "</body></html>"

#Make CGI script executable
chmod +x /var/www/setup.pi/wifi-config.cgi

#Set up local domain name
echo "setup.pi" > /etc/hostname
echo "127.0.0.1 setup.pi" >> /etc/hosts

#Unmask hsotapd
sudo systemctl unmask hostapd.service
sudo systemctl enable hostapd.service

#Restart services
service apache2 restart
service hostapd restart
service dnsmasq restart

echo "ALL SET"
if
