#!/bin/bash

# Installation Dependencies
apt-get install dnsmasq hostapd apache2

# Check internet connection
if ping -q -c 1 -W 1 8.8.8.8 > /dev/null; then
  echo "ALREADY CONNECTED"

  # Add script to run on boot
  cp setup_pi.sh /etc/rc.local

  # Add script to run after boot
  cp setup_pi.sh /etc/init.d/
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
  service hostapd start
  service dnsmasq start
fi

# Create locally hosted web server
a2enmod cgid

# Enable CGI module for Apache
a2enmod cgi

# Start Apache
service apache2 start

# Create GUI for wifi credentials
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
      <input
type="checkbox" id="proxy" name="proxy" value="yes">
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
      <label for="wifi-static">Use static IP:</label><br>
      <div id="static-fields" style="display:none;">
        <label for="ip-address">IP Address:</label><br>
        <input type="text" id="ip-address" name="ip-address"><br>
        <label for="netmask">Netmask:</label><br>
        <input type="text" id="netmask" name="netmask"><br>
        <label for="gateway">Gateway:</label><br>
        <input type="text" id="gateway" name="gateway"><br>
        <label for="nameservers">Nameservers:</label><br>
        <input type="text" id="nameservers" name="nameservers"><br>
      </div>
      <input type="submit" value="Save">
    </form>
    <script>
      document.getElementById("proxy").addEventListener("change", function() {
        var proxyFields = document.getElementById("proxy-fields");
        if (this.checked) {
          proxyFields.style.display = "block";
        } else {
          proxyFields.style.display = "none";
        }
      });
      document.getElementById("wifi-static").addEventListener("change", function() {
        var staticFields = document.getElementById("static-fields");
        if (this.checked) {
          staticFields.style.display = "block";
        } else {
          staticFields.style.display = "none";
        }
      });
    </script>
  </body>
</html>
EOF
# Create wifi-config.cgi script
cat <<EOF > /var/www/setup.pi/wifi-config.cgi
#!/usr/bin/env python

import cgi
import os

form = cgi.FieldStorage()
ssid = form.getvalue("ssid")
psk = form.getvalue("psk")
encryption = form.getvalue("encryption")

if form.getvalue("proxy") == "yes":
  proxy = True
  proxyHost = form.getvalue("proxy-host")
  proxyPort = form.getvalue("proxy-port")
  proxyUsername = form.getvalue("proxy-username")
  proxyPassword = form.getvalue("proxy-password")
  proxyExceptions = form.getvalue("proxy-exceptions")
else:
  proxy = False

if form.getvalue("wifi-static") == "yes":
  static = True
  ipAddress = form.getvalue("ip-address")
  netmask = form.getvalue("netmask")
  gateway = form.getvalue("gateway")
  nameservers = form.getvalue("nameservers")
else:
  static = False

# Write configuration to wpa_supplicant.conf
with open("/etc/wpa_supplicant/wpa_supplicant.conf", "w") as f:
  f.write("ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\n")
  f.write("update_config=1\n")
  f.write("country=GB\n\n")
  f.write("network={\n")
  f.write("  ssid=\"" + ssid + "\"\n")
  if encryption == "wpa" or encryption == "wpa2":
    f.write("  psk=\"" + psk + "\"\n")
    f.write("  key_mgmt=WPA-PSK\n")
    if encryption == "wpa":
      f.write("  proto=WPA\n")
    else:
      f.write("  proto=RSN\n")
      f.write("  pairwise=CCMP\n")
  elif encryption == "wep":
    f.write("  wep_key0=" + psk + "\n")
    f.write("  wep_tx_keyidx=0\n")
    f.write("  key_mgmt=NONE\n")
    f.write("  auth_alg=OPEN\n")
  elif encryption == "eap":
    f.write("  eap=PEAP\n")
    f.write("  identity=" + proxyUsername + "\n")
    f.write("  password=" + proxyPassword + "\n")
    f.write("  ca_cert=\"/etc/ssl/certs/ca-certificates.crt\"\n")
    f.write("  phase1=\"peapver=0\"\n")
    f.write("  phase2=\"auth=MSCHAPV2\"\n")
    f.write("  key_mgmt=WPA-EAP\
  netmask " + netmask + "\n")
    f.write("  gateway " + gateway + "\n")
    f.write("  dns-nameservers " + nameservers + "\n")

# Restart networking service
os.system("service networking restart")

# Redirect to success page
print("Location: success.html")
print("")

EOF

# Create success page
cat <<EOF > /var/www/setup.pi/success.html
<html>
  <head>
    <title>WiFi Configuration Successful</title>
  </head>
  <body>
    <h1>WiFi Configuration Successful</h1>
    <p>Your Raspberry Pi is now connected to the network.</p>
  </body>
</html>
EOF
# Make wifi-config.cgi executable
os.system("chmod +x /var/www/setup.pi/wifi-config.cgi")

# Restart Apache web server
os.system("service apache2 restart")

EOF
exit;
