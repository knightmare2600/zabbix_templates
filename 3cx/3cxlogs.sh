#!/bin/bash

#------------------------------------------------------------------------------#
# Shell script to export CDR logs to email address on a 3CX PBX.               #
#                                                                              #
# Created: 11/11/2019 v0.1  Robert McLay     Initial version                   #
# Updated: 12/11/2019 v0.2  Robert McLay     Document exim4-daemon-light setup #
# Updated: 13/11/2019 v0.3  Robert McLay     Parameterise Sender & Recipient   #
# Updated: 13/11/2019 v0.4  Robert McLay     name log daily from weekly        #
#------------------------------------------------------------------------------#
# To set up exim4-daemon-light:                                                #
#                                                                              #
# sudo apt install exim4-daemon-light ; sudo dpkg-reconfigure exim4-config     #
#                                                                              #
# Edit the settings as follows, presuming your domain is example.com:          #
#                                                                              #
# Type of Server: mail sent by smarthost; no local mail                        #
# System Mail Name: pbx.example.com (i.e. the hostname of this machine)        #
# IP-addresses to listen on for incoming SMTP connections: 127.0.0.1 ; ::1     #
# Other destinations for which mail is accepted: example.com                   #
# Visible domain name for local users: example.com                             #
# IP / hostname of outgoing smarthost: example-com.mail.protection.outlook.com #
# Keep number of DNS-queries minimal (Dial-on-Demand)?: No                     #
# Split configuration into small files?: No                                    #
#                                                                              #
# In 3CX PBX WebUI Go to Settings > CDR > Enable CDR to begin generating logs. #
# Also remember to set the email addresses below, and to configure a cron job  #
# for each night at 01:00 or so.                                               #
#                                                                              #
# You may also need to set up a send connector in office 365. Like this:       #
# portal.office.com > Admin > Exchange Admin > Mail flow > Connectors > Add    #
#                                                                              #
# pbx.example.com CDR Call logs                                                #
# Mail flow scenario:                                                          #
# From: Your organization''s email server                                      #
# To: Office 365                                                               #
# Description: CDR logs sent out from 3CX PBX                                  #
# Status: On                                                                   #
# How to identify email sent from your email server:                           #
# IP address is within these IP address range: 12.34.56.78 (WAN IP of PBX) and #
# the sender's email address is an accepted domain for your organization.      #
#------------------------------------------------------------------------------#

## Dymanic Copyright Konami code
thisyear=`/bin/date +%Y`

## Help function. You'll need this...
function help {
    echo
    echo "  `basename $0` Scrpt to email 3CX CDR logs from previous day to mailbox"
    echo "         COPYLEFT (L) Robert McLay 2019-$thisyear"
    echo
    echo "  Usage: `basename $0` [-h] [--help] <sender email> <recipient email>"
    echo "  e.g: `basename $0` pbx@example.com support@example.com"
    echo
    exit 1
    }

NUMARGS=$#
## DEBUG
#echo -e \\n"Number of arguments: $NUMARGS"

## If user gives -h, --help or no parameters, print help and exit
PARAMETERS=$#

while getopts :h:help: PARAMETERS; do
  case $PARAMETERS in
    \h) # any parameters will always display help
       help
    ;;
    \?) # any parameters will always display help
       help
    ;;
  esac
done

## Turn parameters into variables
PBXSENDER="$1"
RECIPIENT="$2"

## Confirm email addresses are syntax valid. We are _NOT_ checking if the
## mailbox exists or accepts messages. That is *your* responsibility.
if [[ ! "$RECIPIENT" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$ ]]; then
  /bin/echo "Email address $RECIPIENT is invalid."
## And the Sender address
elif [[ ! "$PBXSENDER" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$ ]]; then
  /bin/echo "Email address $PBXSENDER is invalid."
fi

## _DO NOT_ edit below here!
YESTERDAY=`/bin/date --date="yesterday" +%Y/%m/%d`
HASEXIMDL=`/usr/bin/dpkg --list | /bin/grep exim4-daemon-light | /usr/bin/wc -l`

## Confirm exim4-daemon-light is installed.
if [[ $HASEXIMDL -ne 1 ]]; then
  /bin/echo exim4-daemon-light package is not installed. Exiting on safety grounds
  exit 0
fi

## Check that we have root
if [[ $EUID -ne 0 ]]; then
  /bin/echo "You must have root permissions to read call logs. Please run again with sudo, or as root." 2>&1
  exit 0
fi

## Build log file of previous day's call log
/bin/echo 'historyid,callid,duration,time-start,time-answered,time-end,reason-terminated,from-no,to-no,from-dn,to-dn,dial-no,reason-changed,final-number,final-dn,bill-code,bill-rate,bill-cost,bill-name,chain' > /var/log/3CXDailyCallLog.log
/bin/grep "$YESTERDAY" /var/lib/3cxpbx/Instance1/Data/Logs/CDRLogs/cdr.log >> /var/log/3CXDailyCallLog.log
/bin/echo "3CXCallLog.sh,Script to export CDR logs from 3CX PBX for compliance reasons,(C) Copyleft Example1 Ltd" >> /var/log/3CXDailyCallLog.log

## Send email of call log for previous day
/usr/bin/mail -s "3CX call Log for $YESTERDAY" -a "From: $PBXSENDER" "$RECIPIENT" < /var/log/3CXDailyCallLog.log
