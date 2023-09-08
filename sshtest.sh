#!/bin/bash

# Uses netcat (nc) since some firewalls/hosts drop nmap probes

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

# Set the SSH timeout value in seconds (adjust as needed)
ssh_timeout=1

# Set the timeout switch for nc based on OS type
# macOS
if [[ "$(uname)" == "Darwin" ]]; then
    timeout_switch="-G"
# Linux
elif [[ "$(uname)" == "Linux" ]]; then
    timeout_switch="-w"
fi

# Display the date and time
date

# Read IP addresses from the file and test SSH connectivity
while read -r ip; do
    if nc -z "$timeout_switch" $ssh_timeout "$ip" 22 >/dev/null 2>&1; then
        echo "$ip ssh open"
    else
        echo "$ip ssh closed"
    fi
done < "$ip_list"
