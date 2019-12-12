# Zabbix Templates

## About
This repo contains scripts and templates for a zabbix 2.2+ and 3.x zabbix server to do various checks on devics

## Usage
Read the info.txt in each folder for specifics for that template, and then import the template into your Zabbix server, after having confirmed any Macros or Valume Mappings have been added.

Templates

* 3CX PBX / SBC         - Monitor a 3CX PBX / SBC running on Debian Linux - Windows template WIP
* Acronis 12.5 Advanced	- Monitor Acronis 12.5 Advanced Backup jobs via zabbix requires cloning of items on a per host basis. Example script output:
```
Machine hostname: TESTNODE01
Backup plan name: Backup TESTNODE01 to BACKUPSERVER01
Job Start time  : 1984-04-01T13:00:00Z
Job Start stamp : 449668800.0
Job Finish time : 1997-08-29T02:14:00Z
Job Finish stamp: 872817240.0
CompletionResult: ok
```
After importing the template, be sure to clone items and triggers for each of the jobs you wish to monitor. A future update for Zabbix 4.2 will make the jobs a LLD rule to auto-discover backups.

* apc_ups		- Monitor APC UPS using Serial port - see notes on setup
* domain_check          - Check a list of domains for expiry and warn for 14 days or less and go critical for 0 or below
* HP ILO		- Template to Monitor HP ILO using LLD & Template for Zabbix Proxy to confirm scripts are in place. Rememebr to set the Macros:

``` 
* {$ILO}      => ilo.example.com for your ILO host/IP
* {$ILO_USER} => Username with Admin Rights
* {$ILO_PASS} => Password for {$ILO_USER}
```
* IP Fire		- IP Fire template - Allows SNMP Monitoring of IP Fire Firewalls [WIP]
* isc-dhcp-server       - Monitors the ISC DHCP Server on Linux alerting if service is not running
* LAMP Stack		- Confirms all packages required for LAMP stack are installed on Ubuntu VM
* Let's Encrypt         - Confirms Let's Encrypt certbot is properly installed - Does NOT monitor SSL expiry or renewal
* Microsoft Exchange	- Monitor Microsoft Exchange 2010/2013/2016
* nginx			- Monitor nginx Web Server
* qnap_snmp             - SNMP Template for QNAP NAS devices. Requires the NAS.mib from your QNAP's WebUI -> SNMP section
* rdp_users             - Monitors logged in RDP users and alerts for sessions left active
* Security_Watcher      - Checks package versions, build dates, etc. for public CVEs and alerts. NOT a replacement for Vulnerability scanners
* ssl_check             - Checks an SSL certificate for issuer (hello WoSign!) and days to expiry. Alerts for 90, 60 30 days etc.
* RDP Users		- Sends an alert if user is logged in via RDP
* unattended_upgrades   - Monitors the unattended upgrades package for Ubuntu Linux. Raises an alert if a system has a pending reboot or no cront job specified for the cleaning of old kernels (script included)
* vmware_snapshot_check - Checks a VMWare ESXi host and outputs a text file with the current number of snapshots to a file. Requires SSH daemon to be running on ESXi host and SSH keys to be available. The shell script also needs to be available
* VMWare SNMP		- Monitor ESXi via SNMP remember to set the ${SNMP_COMMUNITY} macro and enable SNMP on ESXi
* Windows Update	- Checks Status of windows update on 2008 R2+ Needs EnableRemoteCommands=1 in Zabbix agent configuration
* Windows OS		- Modify Zabbix Templaye to show volume of free space e.g. 7.2GB as well as < 20% in LLD trigger)
* Wordpress		- Monitor wordpress installs and alert if they are out of date

```
```

## Notes
This code has been tested on Zabbix 2.2 and 3.0. Some bugs may be present. Use at your own risk!

Licensed under GPLv3.

## Copyright
Authors: Various: Seee shell scrpts for details
