#!/bin/bash

##----------------------------------------------------------------------------##
## Zabbix check script for esx to check existence of snapshots, consolidation ##
## required and to which VMs the status is applied. Outputs two files which   ##
## are read by zabbix agent to monitor status.                                ##
##                                                                            ##
## Requirements:                                                              ##
##  * /root/.ssh/id_rsa SSH key to permit passwordless login to ESXi          ##
##  * Corresponding public key added to /etc/ssh/keys-root/authorized_keys    ##
##  * /usr/lib/zabbix/externalscripts/snapshot_check.sh to exist              ##
##  * Cron job to exist in /etc/crontab An example of the cron job would be:  ##
##  /usr/lib/zabbix/externalscripts/snapshot_check.sh esx.your.tld 0 1 2>&1   ##
##  * Zabbix 2.2+                                                             ##
##                                                                            ##
## Script tested on vmware esx/esxi: 3.5/4.0/4.1/5.5/6.0/6.5                  ##
##                                                                            ##
## on early version you have to create an alias for vim-cmd                   ##
## #cd /usr/bin                                                               ##
## #ln -s ./vmware-vim-cmd vim-cmd                                            ##
##                                                                            ##
## Created: 18 Dec 2013   Mirko Minuti      Unknown changes                   ##
## Updated: 13 Nov 2015   Robert McLay      Port to Zabbix, but run on proxy  ##
## Updated: 17 Nov 2015   Robert McLay      Use output file to bypass the 30s ##
##                                          limit Zabbix uses on ext checks   ##
## Updated: 17 Nov 2015   Robert McLay      Zabbix regex works out # of snaps ##
## Updated: 18 Nov 2015   Robert McLay      Confirm SSH works, alert if not   ##
## Updated: 19 Nov 2015   Duncan Blair      Only remove file if it exists     ##
## Updated: 25 Nov 2016   Robert McLay      Check for consolidation too       ##
## Updated: 13 Feb 2017   Robert McLay      Fix typo in snapshot count        ##
## Updated: 15 Feb 2017   Robert McLay      Fix snapshot count and logic bug  ##
## Updated: 24 Feb 2017   Robert McLay      Use combined total snapshots, as  ##
##                                          opposed to a VMs total snapshots  ##
## Updated: 27 Mar 2017   Robert McLay      Subtract 1 snap for Replica VMs   ##
##----------------------------------------------------------------------------##

print_usage() {
  echo ""
  echo "Usage: $0 [esxi_hostname] [warn] [crit]"
  echo "where [warn] and [crit] are values of number of allowed snapshots"
  echo ""
  exit 3
}

case "$1" in
  --help)
    print_usage
  ;;
  -h)
    print_usage
  ;;
esac

if [ "$#" -ne "3" ]; then
  print_usage
fi

## Pre-flight checks. Delete any previous files and clear vaiables

## Check to see if the snapshot-status file exists
if [ -f "/usr/lib/zabbix/externalscripts/snapshot-status" ]; then
  ## Delete file if it does exist, to make sure we don't get wonky output
  rm /usr/lib/zabbix/externalscripts/snapshot-status
fi

## check if consolidate-status file exists
if [ -f "/usr/lib/zabbix/externalscripts/consolidation-status" ]; then
  ## Delete file if it does exist, to make sure we don't get wonky output
  rm /usr/lib/zabbix/externalscripts/consolidation-status
fi

## Reset variables
let i=0;
let snaptotal=0;
let snapshotnum=0;
let replicasnaptotal=0;
let replicacount="$2+1";

## Test we can SSH to the host before trying to execute anything
ssh -i /root/.ssh/id_rsa root@"$1" vmware -v
sshstatus=`echo "$?"`

## Confirm SSH connection works, if not flub based on error code
if [ "$sshstatus" -eq "130" ]; then 
  echo "SSH Connect Failed: Please check manually" > /usr/lib/zabbix/externalscripts/snapshot-status
  exit 0
elif [ "$sshstatus" -eq "255" ]; then
  echo "SSH Key Authentication Failed on host $1" > /usr/lib/zabbix/externalscripts/snapshot-status
  exit 0
fi

## Debug code: will return error code of SSH uncomment to confirm. Expected result: 0 i.e. success
#echo "$?"

vms=(`ssh -i /root/.ssh/id_rsa root@$1 vim-cmd vmsvc/getallvms | sed -e '1d' -e 's/ \[.*$//' | awk '$1 ~ /^[0-9]+$/ {print  $1":"substr($0,8,80)}'|sort`);
for vm in "${vms[@]}"; do
id=`echo $vm |awk -F: '{print $1}'`
vmname=`echo $vm |awk -F: '{print $2}'`
snapshotnum=`ssh -i /root/.ssh/id_rsa root@$1 vim-cmd vmsvc/snapshot.get $id |grep "Snapshot Name" |wc -l`
consolidate=`ssh -i /root/.ssh/id_rsa root@$1 vim-cmd vmsvc/get.summary $id |grep "consolidationNeeded" | awk '{ print $3 }'| tr -d ','`

## Debug code, uncomment to confirm check works as one expects. Should (+20p) return true|false
#echo "$consolidate"

## Now check for snapshots and consolidation. I'll use a different file to keep Zabbix logic code
## down consolidation is a bad thing (TM) so if it's happening, then y'all are getting an alert

isreplica=`echo $vmname | cut -d'_' -f 2`

if [ "$isreplica" != "vmpreplica" ]; then
  ## Total snpashots if we are not a replica
  if [ "$snapshotnum" -gt "$2" ]; then
    snap[$i]="$vmname:$snapshotnum";
    let "snaptotal=$snaptotal+$snapshotnum";
    let i++;
  fi
elif [ "$isreplica" == "vmpreplica" ]; then
  ## If we are a replica, then get total snapshots and delete 1 from it (default replica shapshot)
  if [ "$snapshotnum" -gt "$replicacount" ]; then
    snap[$i]="$vmname:$snapshotnum";
    let i++;
  fi
fi

if [ "$consolidate" == "true" ]; then
  ## Debug code, uncomment to confirm logic code works
  #echo "Consolidation status of $vmname is $consolidate"
  echo "$vmname: Needs Consolidation" >> /usr/lib/zabbix/externalscripts/consolidation-status
fi

#echo "$replicasnaptotal"
#echo "$vmname" has "$snaptotal" and snapshotnum is "$snapshotnum"

done

## If /usr/lib/zabbix/externalscripts/consolidation-status does not exist, then no consolidation required
if [ ! -f "/usr/lib/zabbix/externalscripts/consolidation-status" ]; then
  echo "No consolidation required" > /usr/lib/zabbix/externalscripts/consolidation-status
fi

## If total of snapshots is less than the tolerance value (2nd variable) then we're all square
if [ "$snaptotal" -eq 0 ]; then
  echo "$snaptotal snapshots found" > /usr/lib/zabbix/externalscripts/snapshot-status
  exit 0
elif [ "$snaptotal" -lt "$2" ]; then
  echo "0 snapshots found" > /usr/lib/zabbix/externalscripts/snapshot-status
  exit 0
else
  echo "$snaptotal snapshots found on ${snap[@]}"  > /usr/lib/zabbix/externalscripts/snapshot-status
fi

## If total of snapshots is less than the critical level, output that, otherwise lp0 is combusting
if [ "$snaptotal" -le "$3" ]; then
  echo "$snaptotal snapshots found on ${snap[@]}" > /usr/lib/zabbix/externalscripts/snapshot-status
  exit 1
else
  echo "$snaptotal snapshots found on ${snap[@]}" > /usr/lib/zabbix/externalscripts/snapshot-status
  exit 2
fi

exit 0
