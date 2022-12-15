#!/bin/bash

#Step 1: Installation of dependencies
echo "Installing dependencies..."
apt-get install dnsmasq hostapd apache2

#Step 2: Check internet connection
echo "Checking internet connection..."
if ping -q -c 1 -W 1 google.com >/dev/null; then
echo "Internet connection detected. Exiting script."
exit 0
else

#Step 3: Set up access point
echo "No internet connection detected. Setting up access point..."
hostapd /etc/hostapd/hostapd.conf
dnsmasq -C /etc/dnsmasq.conf
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
echo "1" > /proc/sys/net/ipv4/ip_forward
service hostapd start
service dnsmasq start

#Step 4: Create GUI for wifi credentials input
echo "Creating GUI for wifi credentials input..."
cp /var/www/html/index.html /var/www/html/index.html.bak
cat > /var/www/html/index.html <<EOF
  <html>
    <head>
      <title>SETUP PI Wifi Credentials</title>
    </head>
    <body>
      <h1>Enter your wifi credentials:</h1>
      <form action="submit.php" method="post">
        SSID: <input type="text" name="ssid"><br>
        Password: <input type="password" name="password"><br>
        Security Type:
        <input type="radio" name="security" value="wpa" checked>WPA
        <input type="radio" name="security" value="wep">WEP
        <input type="radio" name="security" value="wpa2">WPA2
        <input type="radio" name="security" value="eap">EAP<br>
        Optional Proxy Configuration:
        <input type="checkbox" name="proxy" value="1">HTTP/HTTPS Proxy
        <input type="text" name="proxy_server"><br>
        Proxy Port: <input type="text" name="proxy_port"><br>
        Proxy Username: <input type="text" name="proxy_username"><br>
        Proxy Password: <input type="password" name="proxy_password"><br>
        Proxy Exceptions: <input type="text" name="proxy_exceptions"><br>
        Optional Wifi Static Configuration:
        <input type="checkbox" name="wifi_static" value="1">IP Address
        <input type="text" name="wifi_ip"><br>
        Netmask: <input type="text" name="wifi_netmask"><br>
        Gateway: <input type="text" name="wifi_gateway"><br>
        DNS: <input type="text" name="wifi_dns"><br>
        Secondary DNS: <input type="text" name="wifi_dns_secondary"><br>
        Optional LAN Static Configuration:
        <input type="checkbox" name="lan_static" value="1">IP Address
        <input type="text" name="lan_ip"><br>
        Netmask: <input type="text" name="lan_netmask"><br>
Gateway: <input type="text" name="lan_gateway"><br>
DNS: <input type="text" name="lan_dns"><br>
Secondary DNS: <input type="text" name="lan_dns_secondary"><br>
<input type="submit" value="Submit">
</form>
</body>

  </html>
EOF

#Step 5: Display GUI on connected devices
echo "Displaying GUI on connected devices..."
echo "Connect to the 'SETUP PI' access point to enter your wifi credentials."
echo "Once connected, open a browser and go to 'setup.pi' to access the GUI."

#Step 6: Notify user of successful connection
echo "Notifying user of successful connection..."
cat > /var/www/html/submit.php <<EOF

  <html>
    <head>
      <title>SETUP PI Wifi Credentials</title>
    </head>
    <body>
      <?php
        $ssid = $_POST["ssid"];
        $password = $_POST["password"];
        $security = $_POST["security"];
        $proxy = $_POST["proxy"];
        $proxy_server = $_POST["proxy_server"];
        $proxy_port = $_POST["proxy_port"];
        $proxy_username = $_POST["proxy_username"];
        $proxy_password = $_POST["proxy_password"];
        $proxy_exceptions = $_POST["proxy_exceptions"];
        $wifi_static = $_POST["wifi_static"];
        $wifi_ip = $_POST["wifi_ip"];
        $wifi_netmask = $_POST["wifi_netmask"];
        $wifi_gateway = $_POST["wifi_gateway"];
        $wifi_dns = $_POST["wifi_dns"];
        $wifi_dns_secondary = $_POST["wifi_dns_secondary"];
        $lan_static = $_POST["lan_static"];
        $lan_ip = $_POST["lan_ip"];
        $lan_netmask = $_POST["lan_netmask"];
        $lan_gateway = $_POST["lan_gateway"];
        $lan_dns = $_POST["lan_dns"];
        $lan_dns_secondary = $_POST["lan_dns_secondary"];
		
    if ($ssid && $password && $security) {
      // Update /etc/wpa_supplicant/wpa_supplicant.conf with new wifi credentials
      cp /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf.bak
      cat > /etc/wpa_supplicant/wpa_supplicant.conf <<EOF
      network={
        ssid="$ssid"
        psk="$password"
        key_mgmt=$security
      }
EOF

      // Update /etc/network/interfaces with optional static wifi configuration
      if ($wifi_static) {
        cp /etc/network/interfaces /etc/network/interfaces.bak
cat > /etc/network/interfaces <<EOF
auto wlan0
iface wlan0 inet static
address $wifi_ip
netmask $wifi_netmask
gateway $wifi_gateway
dns-nameservers $wifi_dns $wifi_dns_secondary
EOF
} // Update /etc/dhcpcd.conf with optional static LAN configuration
      if ($lan_static) {
        cp /etc/dhcpcd.conf /etc/dhcpcd.conf.bak
        cat > /etc/dhcpcd.conf <<EOF
        interface eth0
        static ip_address=$lan_ip/24
        static routers=$lan_gateway
        static domain_name_servers=$lan_dns $lan_dns_secondary
EOF
      }

      // Update /etc/environment with optional proxy configuration
      if ($proxy) {
        cp /etc/environment /etc/environment.bak
        cat > /etc/environment <<EOF
        http_proxy=http://$proxy_server:$proxy_port
        https_proxy=http://$proxy_server:$proxy_port
        ftp_proxy=http://$proxy_server:$proxy_port
        no_proxy="localhost,127.0.0.1,$proxy_exceptions"
        HTTP_PROXY=http://$proxy_server:$proxy_port
        HTTPS_PROXY=http://$proxy_server:$proxy_port
        FTP_PROXY=http://$proxy_server:$proxy_port
        NO_PROXY="localhost,127.0.0.1,$proxy_exceptions"
EOF

        if ($proxy_username && $proxy_password) {
          cat >> /etc/environment <<EOF
          http_proxy=http://$proxy_username:$proxy_password@$proxy_server:$proxy_port/
          https_proxy=http://$proxy_username:$proxy_password@$proxy_server:$proxy_port/
          ftp_proxy=http://$proxy_username:$proxy_password@$proxy_server:$proxy_port/
          HTTP_PROXY=http://$proxy_username:$proxy_password@$proxy_server:$proxy_port/
          HTTPS_PROXY=http://$proxy_username:$proxy_password@$proxy_server:$proxy_port/
          FTP_PROXY=http://$proxy_username:$proxy_password@$proxy_server:$proxy_port/
EOF
        }
      }

      // Restart networking service to apply changes
      service networking restart

      // Check internet connection
      if ping -q -c 1 -W 1 google.com >/dev/null; then
        echo "<h1>Successfully connected to $ssid!</h1>"
      else
        echo "<h1>Connection failed. Please try again.</h1>"
      }
    } else {
      echo "<h1>Please enter all required fields.</h1>"
    }
  ?>
</body>
  </html>
  EOF

Step 7: Run script on boot
echo "Adding script to run on boot..."
cp /etc/rc.local /etc/rc.local.bak
cat > /etc/rc.local <<EOF
#!/bin/bash

Run script on boot
/path/to/script/raspbian_bullseye_64-bit.sh

exit 0
EOF

echo "Done. Script will run on boot."
