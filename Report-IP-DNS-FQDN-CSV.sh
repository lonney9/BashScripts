#!/bin/bash
 
# This (ugly) script finds Linux hosts, and reports their IP address, FQDN hostname, and name servers.
# Outputs results in CSV format.
# Details:
#  nmap is used to scan IP ranges for hosts listing on port 22, then
#   Remote ssh command is run to connect to each host, find FQDN (hostname -f) and configured name severs (resolv.conf)
#   This assumes the user running the script has the privilege to login to each host via SSH
#   The RSA key fingerprint prompt is auto accepted and the RSA key fingerprint is then discarded
#   so that your ~/.ssh/known_hosts file is not filled up with hundreds or thousands of  RSA key fingerprints
#  Results are output to CSV file.
 
# IP range for nmap to scan. E.g. "172.16.1.10-100" will scan .10 to .100 range of that subnet.
# CDIR notation works too. 
iprange="10.0.0.0/16"
 
# Date.
date=`date +%b-%d-%Y`
 
# File to write resuts out to.
outputfile="ClientDnsReport_${date}.csv"
 
# New line.
NL=$'\n'
 
# Prompt for password for remote ssh commands.
read -sp 'Password: ' SSHPASS
export SSHPASS
 
# Write CSV header.
echo "IP,Hostname,NS1,NS2,NS3,NS4" > $outputfile
 
# nmap command to scan for hosts listening on port 22 and build a list of IP addresses.
echo ""
echo "Scanning for Linux hosts in range ${iprange}.."
hostlist=`nmap ${iprange} -p22 --excludefile nmap-exclude.txt --open -oG - | grep "/open" | awk '{ print $2 }'`
 
# Count and display number of hosts found.
hostcount=`echo "$hostlist" | wc -l`
echo "Found ${hostcount} hosts!"
 
# Loop through hostlist.
echo "Querying.."
 
for host in $hostlist
do
  
 # Display host being queried.
 echo "$host"
  
 # Get FQDN hostname and name servers from resolv.conf.
 sshcmdhostdn=`sshpass -e ssh -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o ConnectTimeout=30 $host "hostname -f"`
 sshcmdresolv=`sshpass -e ssh -q -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -o ConnectTimeout=30 $host "cat /etc/resolv.conf"`
  
 # Extract nameserver IP addresses from resolv.conf.
 nameservers=`echo "$sshcmdresolv" | grep nameserver | awk '{print $2}'`
  
 # Combine record together with IP, FQDN hostname, and name servers. One field per line.
 result="${host}${NL}${sshcmdhostdn}${NL}${nameservers}"
  
 # Convert record to CSV format - fields on one line separated with a comma, and write the record out.
 echo "${result}" | paste -sd ',' >> $outputfile
  
done
 
echo "Done, see $outputfile"
