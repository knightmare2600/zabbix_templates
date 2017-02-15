#Zabbix Templates
##About
This repo contains scripts and templates for a zabbix 2.2+ and 3.x zabbix server to do various checks on devics

##Usage
Read the info.txt in each folder for specifics for that template, and then import the template into your Zabbix server, after having confirmed any Macros or Valume Mappings have been added.

Templates

* 3CX PBX               - Monitor a 3CX PBX running on Linux Debian - Windows template WIP
* domain_check          - Check a list of domains for expiry and warn for 14 days or less and go critical for 0 or below
* qnap_snmp             - SNMP Template for QNAP NAS devices. Requires the NAS.mib from your QNAP's WebUI -> SNMP section
* isc-dhcp-server       - Monitors the ISC DHCP Server on Linux alerting if service is not running
* Security_Watcher      - Checks package versions, build dates, etc. for public CVEs and alerts. NOT a replacement for Vulnerability scanners
* ssl_check             - Checks an SSL certificate for issuer (hello WoSign!) and days to expiry. Alerts for 90, 60 30 days etc.
* unattended_upgrades   - Monitors the unattended upgrades package for Ubuntu Linux. Raises an alert if a system has a pending reboot or no cront job specified for the cleaning of old kernels (script included)
* vmware_snapshot_check - Checks a VMWare ESXi host and outputs a text file with the current number of snapshots to a file. Requires SSH daemon to be running on ESXi host and SSH keys to be available. The shell script also needs to be available

```
```

##Notes
This code has been tested on Zabbix 2.2 and 3.0. Some bugs may be present. Use at your own risk!

Licensed under GPLv3.

##
Authors: Various: Seee shell scrpts for details
