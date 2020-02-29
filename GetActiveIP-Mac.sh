#!/bin/bash
# This will return the IP address of the interface with the default route on MacOS
ipconfig getifaddr `route -n get default | grep interface | sed 's/interface: //g'`
