#!/bin/bash

#Check if internet connection is available
if [ "$(ping -c 1 8.8.8.8 | grep '100% packet loss')" != "" ]; then
#Turn on wireless access point with no password
sudo apt-get install dnsmasq hostapd
sudo systemctl stop dnsmasq
sudo systemctl stop hostapd

#Configure access point settings
sudo cp /etc/dhcpcd.conf /etc/dhcpcd.conf.bak
echo "denyinterfaces wlan0" | sudo tee -a /etc/dhcpcd.conf
sudo systemctl restart dhcpcd

#Create access point configuration file
sudo cp /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf.bak
echo "interface=wlan0" | sudo tee /etc/hostapd/hostapd.conf
echo "driver=nl80211" | sudo tee -a /etc/hostapd/hostapd.conf
echo "ssid=SETUP PI" | sudo tee -a /etc/hostapd/hostapd.conf
echo "hw_mode=g" | sudo tee -a /etc/hostapd/hostapd.conf
echo "channel=7" | sudo tee -a /etc/hostapd/hostapd.conf
echo "macaddr_acl=0" | sudo tee -a /etc/hostapd/hostapd.conf
echo "auth_algs=1" | sudo tee -a /etc/hostapd/hostapd.conf
echo "ignore_broadcast_ssid=0" | sudo tee -a /etc/hostapd/hostapd.conf

#Configure dnsmasq for access point
sudo cp /etc/dnsmasq.conf /etc/dnsmasq.conf.bak
echo "interface=wlan0" | sudo tee /etc/dnsmasq.conf
echo "dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h" | sudo tee -a /etc/dnsmasq.conf

#Enable access point on boot
sudo systemctl enable hostapd
sudo systemctl enable dnsmasq

#Start access point
sudo systemctl start hostapd
sudo systemctl start dnsmasq

#Create GUI for wifi setup
sudo apt-get install python3-tk
python3 -m tkinter -c "from tkinter import ;
app = Tk();
app.title('Wifi Setup');
label1 = Label(app, text='Enter wifi credentials:');
label1.pack();
ssid_label = Label(app, text='SSID:');
ssid_label.pack();
ssid_entry = Entry(app);
ssid_entry.pack();
password_label = Label(app, text='Password:');
password_label.pack();
password_entry = Entry(app, show='');
password_entry.pack();
def on_click():
ssid = s



