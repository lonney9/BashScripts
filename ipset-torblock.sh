#!/bin/bash
# Tor exit node ipsets blocklist #
# Run on system boot, and schdule with cron once per day or more often.  Note cron may not know paths to iptables, curl etc, update to absolute path on your system. #
# Should variablize file paths, nic interface, ipset name, and iptables cmd to make it nice #
iptables -C INPUT -i ens3 -m set --match-set torblock src -j DROP > /dev/null 2>&1
if [ $? -ne 0 ] && [ -f /etc/iptables/ipsets/torblock.ipset ]; then
    # iptables rule missing (reboot?) and saved ipset file exists, load it. #
    echo "Restoring from saved ipset file"
    iptables -D INPUT -i ens3 -m set --match-set torblock src -j DROP > /dev/null 2>&1
    ipset -X torblock
    ipset restore -file /etc/iptables/ipsets/torblock.ipset
    # Assumes connection tracking rule is 1st to allow related connections back in, insert rule 2nd. #
    iptables -I INPUT 2 -i ens3 -m set --match-set torblock src -j DROP
else
    # iptables rule exists, or saved ipset file does not, re-create ipset (updating it) and save. #
    iptables -D INPUT -i ens3 -m set --match-set torblock src -j DROP 2>/dev/null
    ipset -X torblock
    ipset -N torblock iphash
    curl -k -s -S "https://check.torproject.org/torbulkexitlist" | xargs -n 1 ipset -A torblock
    if [ $? -ne 0 ]; then
        # If the download fails, reload from saved ipset file and re-insert iptables rule. #
        echo "Download failed, reload last saved ipset"
        ipset -X torblock
        ipset restore -file /etc/iptables/ipsets/torblock.ipset
        iptables -I INPUT 2 -i ens3 -m set --match-set torblock src -j DROP
        # we're done, busting out #
        exit 1
    fi
    # ipset download and creation suceeded, save it and re-insert iptables rule. #
    echo "Download suceeded, ipset updated and saved"
    ipset save torblock -file /etc/iptables/ipsets/torblock.ipset
    iptables -I INPUT 2 -i ens3 -m set --match-set torblock src -j DROP
fi
