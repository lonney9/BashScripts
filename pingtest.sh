#!/bin/bash

# Ping a list of IP addresses to see if they are up or down

# Quickly generate a list of IPs from a CIDR using nmap, eg:
# nmap -sL -n 192.168.56.0/22 | awk '/Nmap scan report/{print $NF}' > ip_list.txt

# Set the default IP list file name
default_ip_list="ip_list.txt"

# Check if an IP list file name is provided as an argument
if [ $# -eq 0 ]; then
    ip_list="$default_ip_list"
else
    ip_list="$1"
fi

# Check if the specified IP list file exists
if [ ! -e "$ip_list" ]; then
    echo "Error: IP list file '$ip_list' not found."
    exit 1
fi

# Set the timeout value in seconds (adjust as needed)
ping_timeout=1

# Display the date and time
date

# Read IP addresses from the file and ping each one
while read -r ip; do
    if ping -c 1 -W $ping_timeout "$ip" >/dev/null 2>&1; then
        echo "$ip is up"
    else
        echo "$ip is down"
    fi
done < "$ip_list"