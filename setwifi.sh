#!/bin/bash

# Installation Dependencies
apt update
apt install dnsmasq hostapd apache2

# Check internet connection
if ping -q -c 1 -W 1 8.8.8.8 > /dev/null; then
  echo "ALREADY CONNECTED"

  # Add script to run on boot
  cp setwifi.sh /etc/rc.local

  # Add script to run after boot
  cp setwifi.sh /etc/init.d/
else
  # Display message on Raspberry Pi HDMI Output
  echo "Connect to the 'SETUP PI - Network' to enter WIFI credentials"

  # Turn into wireless access point
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

  # Configure DHCP server
  cat > /etc/dnsmasq.conf <<EOF
interface=wlan0
dhcp-range=10.0.0.2,10.0.0.5,255.255.255.0,12h
dhcp-option=3,10.0.0.1
dhcp-option=6,10.0.0.1
EOF

  # Enable IP forwarding and NAT
  echo 1 > /proc/sys/net/ipv4/ip_forward
  iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

  # Start services
  systemctl start hostapd
  systemctl start dnsmasq
fi

# Create locally hosted web server
a2enmod cgid

# Enable CGI module for Apache
a2enmod cgi

# Start Apache
systemctl start apache2

# Create GUI for wifi credentials
sudo cat > /var/www/setup.pi/index.html <<EOF

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
      <input type="checkbox" id="static" name="static" value="yes">
      <label for="static">Use static IP:</label><br>
      <div id="static-fields" style="display:none;">
        <label for="static-ip">Static IP:</label><br>
        <input type="text" id="static-ip" name="static-ip"><br>
        <label for="static-gateway">Gateway:</label><br>
        <input type="text" id="static-gateway" name="static-gateway"><br>
        <label for="static-netmask">Netmask:</label><br>
        <input type="text" id="static-netmask" name="static-netmask"><br>
        <label for="static-dns1">Primary DNS:</label><br>
        <input type="text" id="static-dns1" name="static-dns1"><br>
        <label for="static-dns2">Secondary DNS:</label><br>
        <input type="text" id="static-dns2" name="static-dns2"><br>
      </div>
      <input type="submit" value="Submit">
    </form>
  </body>
</html>
EOF

# Create CGI script for processing form input
sudo cat > /var/www/setup.pi/wifi-config.cgi <<EOF
#!/bin/bash

# Get form input
ssid=$(echo " $QUERY_STRING" | awk -F '[&=]' '{print $3}')
psk=$(echo " $QUERY_STRING" | awk -F '[&=]' '{print $5}')
encryption=$(echo " $QUERY_STRING" | awk -F '[&=]' '{print $7}')
proxy=$(echo " $QUERY_STRING" | awk -F '[&=]
` '{print $9}')
proxy_host=$(echo " $QUERY_STRING" | awk -F '[&=]' '{print $11}')
proxy_port=$(echo " $QUERY_STRING" | awk -F '[&=]' '{print $13}')
proxy_username=$(echo " $QUERY_STRING" | awk -F '[&=]' '{print $15}')
proxy_password=$(echo " $QUERY_STRING" | awk -F '[&=]' '{print $17}')
proxy_exceptions=$(echo " $QUERY_STRING" | awk -F '[&=]' '{print $19}')
static=$(echo " $QUERY_STRING" | awk -F '[&=]' '{print $21}')
static_ip=$(echo " $QUERY_STRING" | awk -F '[&=]' '{print $23}')
static_gateway=$(echo " $QUERY_STRING" | awk -F '[&=]' '{print $25}')
static_netmask=$(echo " $QUERY_STRING" | awk -F '[&=]' '{print $27}')
static_dns1=$(echo " $QUERY_STRING" | awk -F '[&=]' '{print $29}')
static_dns2=$(echo " $QUERY_STRING" | awk -F '[&=]' '{print $31}')

# Update WiFi configuration
if [ "$encryption" == "wpa" ]; then
  wpa_config="wpa=2"
elif [ "$encryption" == "wep" ]; then
  wpa_config="wep_key0=$psk"
elif [ "$encryption" == "wpa2" ]; then
  wpa_config="wpa=3"
elif [ "$encryption" == "eap" ]; then
  wpa_config="ieee8021x=1"
else
  wpa_config=""
fi

cat > /etc/wpa_supplicant/wpa_supplicant.conf <<EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=DE

network={
  ssid="$ssid"
  psk="$psk"
  $wpa_config
}
EOF

if [ "$static" == "yes" ]; then
  cat > /etc/dhcpcd.conf <<EOF
interface wlan0
static ip_address=$static_ip
static routers=$static_gateway
static domain_name_servers=$static_dns1 $static_dns2
EOF
else
  echo "" > /etc/dhcpcd.conf
fi

if [ "$proxy" == "
yes" ]; then
  cat > /etc/apt/apt.conf.d/95proxies <<EOF
Acquire::http::Proxy "http://$proxy_username:$proxy_password@$proxy_host:$proxy_port";
Acquire::https::Proxy "https://$proxy_username:$proxy_password@$proxy_host:$proxy_port";
EOF
else
  echo "" > /etc/apt/apt.conf.d/95proxies
fi

# Restart networking services
systemctl restart dhcpcd
systemctl restart wpa_supplicant

# Redirect back to form
echo "Content-type: text/html"
echo ""
echo "<html>"
echo "<head>"
echo "  <meta http-equiv="refresh" content="0;url=http://setup.pi/">"
echo "</head>"
echo "<body>"
echo "</body>"
echo "</html>"

# Make CGI script executable
chmod +x /var/www/setup.pi/wifi-config.cgi

# Create HTML page for success message
sudo cat > /var/www/setup.pi/success.html <<EOF
<html>
  <head>
    <title>SETUP PI Wifi Configuration</title>
  </head>
  <body>
    <h1>WiFi Configuration Successful</h1>
    <p>Your WiFi configuration has been updated successfully. You can now connect to the internet using your WiFi network.</p>
  </body>
</html>
EOF
``
