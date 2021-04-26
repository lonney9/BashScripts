#!/bin/bash
# Pings list of IP addresses from file (one per line) and logs results to a CSV file
# Found network or hosts were blocking/evading nmap probes
# Example command to generate IP address lists
# nmap -sL -n 192.168.56.0/22 | awk '/Nmap scan report/{print $NF}' > ipaddress-list.txt

infile="ipaddress-list.txt"
outfile="ipaddress-results.csv"

date > "$outfile"
echo "IP Address,State" >> "$outfile"

while read output; do
    echo -n "$output" >> "$outfile"
    if ping -c1 "$output" > /dev/null 2>&1; then
        echo ",UP" >> "$outfile"
    else
        echo ",DOWN" >> "$outfile"
    fi
done < $infile
