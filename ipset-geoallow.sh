#!/bin/bash
# Geo whitelist ipsets script, drops connections from countries NOT whitelisted #
# Run on system boot, and schdule with cron once per day #
# See https://www.ipdeny.com/ipblocks/ for list #
# Should variablize country codes (line 20), file paths, nic interface, ipset name, and iptables cmd to make it nice #
iptables -C INPUT -i ens3 -m set ! --match-set geoallow src -j DROP > /dev/null 2>&1
if  [ ! "$?" = 0 ] && [ -f /etc/iptables/ipsets/geoallow.ipset ]; then
    # iptables rule missing (reboot?) and saved ipset file exists, load it.
    echo "Restoring from saved ipset file"
    iptables -D INPUT -i ens3 -m set ! --match-set geoallow src -j DROP > /dev/null 2>&1
    ipset -X geoallow
    ipset restore -file /etc/iptables/ipsets/geoallow.ipset
    # Assumes connection tracking rule is 1st to allow related connections back in, insert rule 2nd #
    iptables -I INPUT 2 -i ens3 -m set ! --match-set geoallow src -j DROP
else
    # iptables rule exists, or saved ipset file does not, re-create ipset (updating it) and save #
    iptables -D INPUT -i ens3 -m set ! --match-set geoallow src -j DROP
    ipset -X geoallow
    ipset -N geoallow nethash maxelem 131072
    for i in au ca nz us; do
        echo "${i}"
        curl -k -s -S "https://www.ipdeny.com/ipblocks/data/countries/${i}.zone" | xargs -n 1 ipset -A geoallow
        if  [ ! "$?" = 0 ]; then
            # If the download fails, reload from saved ipset file and re-insert iptables rule #
            echo "Download failed, reload last saved ipset"
            ipset -X geoallow
            ipset restore -file /etc/iptables/ipsets/geoallow.ipset
            iptables -I INPUT 2 -i ens3 -m set ! --match-set geoallow src -j DROP
            # we're done, busting out #
            exit 1
        fi
    done
    # ipset download and creation suceeded, save it and re-insert iptables rule #
    echo "Download suceeded, ipset updated and saved"
    ipset save geoallow -file /etc/iptables/ipsets/geoallow.ipset
    iptables -I INPUT 2 -i ens3 -m set ! --match-set geoallow src -j DROP
fi
