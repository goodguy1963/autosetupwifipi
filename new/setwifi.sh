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
cp hostapd.conf /etc/hostapd/

  # Configure DHCP server
cp dnsmasq.conf /etc/ 



  # Enable IP forwarding and NAT
  echo 1 > /proc/sys/net/ipv4/ip_forward
  iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

  # Start services
  
  sudo systemctl unmask hostapd.service
  sudo systemctl start hostapd.service
  systemctl start dnsmasq


# Create locally hosted web server
a2enmod cgid

# Enable CGI module for Apache
a2enmod cgi

# Start Apache
systemctl start apache2

# Create Directory and Files
sudo mkdir -p /var/www/setup.pi
sudo touch /var/www/setup.pi/index.html
sudo touch /var/www/setup.pi/wifi-config.cgi

# Create GUI for wifi credentials
cp index.html /var/www/setup.pi/ 

# Create CGI script for processing form input
cp wifi-config.cgi  /var/www/setup.pi/

cp wpa_supplicant.conf /etc/wpa_supplicant/ 

if [ "$static" == "yes" ]; then
  cp dhcpcd.conf /etc/ 

EOF

else
  echo "" > /etc/dhcpcd.conf
fi

if [ "$proxy" == "yes" ]; then
  cp /etc/apt/apt.conf.d/95proxies 

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
cp success.html /var/www/setup.pi/

``
fi
