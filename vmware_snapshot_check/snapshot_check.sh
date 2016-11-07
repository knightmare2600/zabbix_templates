#!/bin/bash

##----------------------------------------------------------------------------##
## Zabbix check script for esx to check existence of snapshot and where are.  ##
## Script tested on vmware esx/esxi: 3.5/4.0/4.1/5.5/6.0                      ##
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

i=0
total=0

## Test we can SSH to the host before trying to execute anything
testconnection=`ssh -i /root/.ssh/id_rsa root@$1 vmware -v`

if [ "$?" -eq "130" ]; then 
  echo "SSH Connection Failed: Please check manually" > /usr/lib/zabbix/externalscripts/snapshot-status
  exit 0
elif [ "$?" -eq "255" ]; then
  echo "SSH Key Authentication Failed: Please check manually" > /usr/lib/zabbix/externalscripts/snapshot-status
  exit 0
fi

echo "$?"

vms=(`ssh -i /root/.ssh/id_rsa root@$1 vim-cmd vmsvc/getallvms | sed -e '1d' -e 's/ \[.*$//' | awk '$1 ~ /^[0-9]+$/ {print  $1":"substr($0,8,80)}'|sort`);
for vm in "${vms[@]}"; do
id=`echo $vm |awk -F: '{print $1}'`
vmname=`echo $vm |awk -F: '{print $2}'`
result=`ssh -i /root/.ssh/id_rsa root@$1 vim-cmd vmsvc/snapshot.get $id |grep "Snapshot Name" |wc -l`
  if [ $result -ge 1 ]; then
    snap[$i]="$vmname:$result";
    let "total=$total+$result";
    let i++;
  fi
done

## Check to see if the snapshot-status file exists
if [ -f "/usr/lib/zabbix/externalscripts/snapshot-status" ]; then
  ## Delete file if it does exist, to make sure we don't get wonky output
  rm /usr/lib/zabbix/externalscripts/snapshot-status
fi

## If total of snapshots is less than the tolerance value (2nd variable) then we're all square
if [ $total -le $2 ] ; then
  if [ $total -eq 0 ] ; then
    echo "$total snapshots found" > /usr/lib/zabbix/externalscripts/snapshot-status
    exit 0
  else
    echo "$total snapshots found on ${snap[@]}"  > /usr/lib/zabbix/externalscripts/snapshot-status
    exit 0
  fi
fi

## If total of snapshots is less than the critical level, output that, otherwise lp0 is combusting
if [ $total -le $3 ] ; then
  echo "$total snapshots found on ${snap[@]}" > /usr/lib/zabbix/externalscripts/snapshot-status
  exit 1
else
  echo "$total snapshots found on ${snap[@]}" > /usr/lib/zabbix/externalscripts/snapshot-status
  exit 2
fi

