#!/bin/bash

# Get form input
ssid=$(echo " $QUERY_STRING" | awk -F '[&=]' '{print $3}')
psk=$(echo " $QUERY_STRING" | awk -F '[&=]' '{print $5}')
encryption=$(echo " $QUERY_STRING" | awk -F '[&=]' '{print $7}')
proxy=$(echo " $QUERY_STRING" | awk -F '[&=]' '{print $9}')
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
