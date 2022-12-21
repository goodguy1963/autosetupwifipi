#!/bin/bash

Installation Dependencies
apt update
apt install dnsmasq hostapd apache2

Check internet connection


if ping -q -c 1 -W 1 8.8.8.8 > /dev/null; then
echo "ALREADY CONNECTED"

Add script to run on boot
cp setwifi1.sh /etc/rc.local

Add script to run after boot
cp setwifi1.sh /etc/init.d/
else

Display message on Raspberry Pi HDMI Output
echo "Connect to the 'SETUP PI - Network' to enter WIFI credentials"

sudo -s

Turn into wireless access point
sudo cat <<EOF > /etc/hostapd/hostapd.conf
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

Configure DHCP server
sudo cat <<EOF > /etc/dnsmasq.conf
interface=wlan0
dhcp-range=10.0.0.2,10.0.0.5,255.255.255.0,12h
dhcp-option=3,10.0.0.1
dhcp-option=6,10.0.0.1
EOF

Enable IP forwarding and NAT
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

Start services
sudo systemctl unmask hostapd.service
sudo systemctl enable hostapd.service
sudo systemctl start hostapd.service
systemctl start dnsmasq
fi

Create locally hosted web server

a2enmod cgid
systemctl restart apache2

Enable CGI module for Apache
a2enmod cgi

Start Apache
systemctl start apache2

Create Directory and Files
sudo mkdir -p /var/www/setup.pi
sudo touch /var/www/setup.pi/index.html
sudo touch /var/www/setup.pi/wifi-config.cgi

Create GUI for wifi credentials
sudo cat <<EOF > /var/www/setup.pi/index.html

<!-- Create GUI for wifi credentials -->
<html>
  <head>
    <title>SETUP PI Wifi Configuration</title>
  </head>
  <body>
    <h1>SETUP PI Wifi Configuration</h1>
    <form action="wifi-config.cgi" method="post">
      <!-- Option to manually enter SSID and password -->
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
      <!-- Option to scan for nearby wifi networks -->
      <button type="button" id="scan-button" onclick="scanWifi()">Scan for nearby wifi networks</button>
      <br><br>
      <div id="scan-results" style="display:none;"></div>
      <!-- Option to use proxy -->
      <input type="checkbox" id="proxy" name="proxy" value="yes">
      <label for="proxy">Use proxy:</label><br>
      <div id="proxy-fields" style="display:none;">
        <label for="proxy-host">Proxy Host:</label><br>
        <input type="text" id="proxy-host" name="proxy-host"><br>
        <label for="proxy-port">Proxy Port:</label><br>
        <input type="text" id="proxy-port" name="proxy-port"><br>
        <label for="proxy-username">Proxy Username:</label><br>
        <input type="text" id="proxy-username"name="proxy-username"><br>
<label for="proxy-password">Proxy Password:</label><br>
<input type="password" id="proxy-password" name="proxy-password"><br>
</div>
<br>
<input type="submit" value="Submit">
</form>
<!-- JavaScript for wifi network scan -->
<script>
// Function to scan for nearby wifi networks
function scanWifi() {
// Check if device supports Geolocation and Network Information API
if (navigator.geolocation && navigator.networkInformation) {
// Get device location
navigator.geolocation.getCurrentPosition(function(position) {
console.log("Device location: ", position.coords);
// Get nearby wifi networks
navigator.networkInformation.getNetworkInformation().then(function(network) {
console.log("Nearby wifi networks: ", network.wifi);
// Display nearby wifi networks in a list
var scanResults = document.getElementById("scan-results");
scanResults.innerHTML = "";
for (var i = 0; i < network.wifi.length; i++) {
var wifi = network.wifi[i];
scanResults.innerHTML += "<input type='radio' name='ssid' value='" + wifi.ssid + "'>" + wifi.ssid + "<br>";
}
scanResults.style.display = "block";
});
}, function(error) {
console.error("Error getting device location: ", error);
});
} else {
console.error("Geolocation or Network Information API not supported");
}
}
</script>

  </body>
</html>
EOF
Create script to handle wifi configuration
sudo cat <<EOF > /var/www/setup.pi/wifi-config.cgi
#!/usr/bin/env python
import cgi
import subprocess

form = cgi.FieldStorage()
ssid = form.getvalue('ssid')
psk = form.getvalue('psk')
encryption = form.getvalue('encryption')
proxy = form.getvalue('proxy')
proxy_host = form.getvalue('proxy-host')
proxy_port = form.getvalue('proxy-port')
proxy_username = form.getvalue('proxy-username')
proxy_password = form.getvalue('proxy-password')

if not ssid or not psk:
print("Content-type: text/html\n")
print("Error: SSID and password are required fields")
exit()

if not proxy_port.isdigit():
print("Content-type: text/html\n")
print("Error: Proxy port must be a number")
exit()

Create wifi configuration file
with open('/etc/wpa_supplicant/wpa_supplicant.conf', 'w') as f:
f.write('ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\n')
f.write('update_config=1\n')
f.write('network={\n')
f.write(f'ssid="{ssid}"\n')
f.write(f'psk="{psk}"\n')
f.write(f'key_mgmt={encryption}\n')
if proxy == :</label><br>
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
</div>
<input type="submit" value="Submit">
</form>

  </body>
</html>
EOF
Create script to handle wifi configuration
sudo cat <<EOF > /var/www/setup.pi/wifi-config.cgi
#!/usr/bin/env python
import cgi
import subprocess

form = cgi.FieldStorage()
ssid = form.getvalue('ssid')
psk = form.getvalue('psk')
encryption = form.getvalue('encryption')
proxy = form.getvalue('proxy')
proxy_host = form.getvalue('proxy-host')
proxy_port = form.getvalue('proxy-port')
proxy_username = form.getvalue('proxy-username')
proxy_password = form.getvalue('proxy-password')

if not ssid or not psk:
print("Content-type: text/html\n")
print("Error: SSID and password are required fields")
exit()

if not proxy_port.isdigit():
print("Content-type: text/html\n")
print("Error: Proxy port must be a number")
exit()

Create wifi configuration file
with open('/etc/wpa_supplicant/wpa_supplicant.conf', 'w') as f:
f.write('ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\n')
f.write('update_config=1\n')
f.write('network={\n')
f.write(f'ssid="{ssid}"\n')
f.write(f'psk="{psk}"\n')
f.write(f'key_mgmt={encryption}\n')
if proxy == 'yes':
f.write(f'proxy_address={proxy_host}\n')
f.write(f'proxy_port={proxy_port}\n')
f.write(f'proxy_username={proxy_username}\n')
f.write(f'proxy_password={proxy_password}\n')
f.write('}')

Restart networking service
subprocess.run(['systemctl', 'restart', 'networking'])

print("Content-type: text/html\n")
print("Wifi configuration saved and applied successfully")
EOF

