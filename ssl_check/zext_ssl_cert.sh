#! /bin/bash

#------------------------------------------------------------------------------#
#                                                                              #
# Script checks for num of days until certificate expires, issuing CA Vendor,  #
# certificate thumbprint, Unknown/Bad CAs (hello woSign!), etc.                #
# on switch passed on command line.                                            #
#                                                                              #
# Created: xx XXX XXXX   aperto.fr           Initial version for Zabbix        #
# Updated: xx XXX 2016   racooper@tamu.edu   Unknown edits & additions         #
# Updated: 22 Nov 2018   knightmare          Check thumbprint & Serial now     #
# Updated: 04 Jan 2019   knightmare          Grab a copy of the cert globally  #
#                                            to fix 'sed broken pipe' bug      #
# Updated: 10 Jan 2019   knightmare          Add -p Primary cert & -x SANs     #
#                                                                              #
#------------------------------------------------------------------------------#

DEBUG=0
if [ $DEBUG -gt 0 ]
then
    exec 2>>/tmp/my.log
    set -x
fi

func=$1
host=$2
port=$3
sni=$4
proto=$5

if [ -z "$sni" ]
then
    servername=$host
else
    servername=$sni
fi

if [ -n "$proto" ]
then
    starttls="-starttls $proto"
fi

## Assign certificate to variable, as this avoids the sed: couldn't flush stdout: Broken pipe error per
## https://www.zabbix.com/forum/zabbix-help/45210-ssl-certificate-check-is-not-suitable-for-value-type
certificate=`openssl s_client -servername $servername -connect $host:$port -showcerts $starttls </dev/null 2>/dev/null | sed -n '/BEGIN CERTIFICATE/,/END CERT/p'`

case $func in

-c)
checkhost=`echo "$certificate" | openssl x509 -noout -checkhost "$host"`

if [ -n "$end_date" ]
then
    echo "$checkhost"
fi
;;

-d)
end_date=`echo "$certificate" | openssl x509 -enddate -noout 2>/dev/null | sed -n 's/notAfter=//p' | sed 's/ GMT//g'`

if [ -n "$end_date" ]
then
    end_date_seconds=`date '+%s' --date "$end_date"`
    now_seconds=`date '+%s'`
    echo "($end_date_seconds-$now_seconds)/24/3600" | bc
fi
;;

-i)
issue_dn=`echo "$certificate" | openssl x509 -text 2>/dev/null | sed -n 's/ *Issuer: *//p'`

if [ -n "$issue_dn" ]
then
    issuer=`echo $issue_dn | sed -n 's/.*CN=*//p' | tr -d =`
    echo $issuer
fi
;;

-p)
subject=`echo "$certificate" | openssl x509 -noout -subject | awk -F= '{ print $NF }'i`

if [ -n "$subject" ]
then
    echo "$subject"
fi
;;

-r)
ocspurl=`echo "$certificate" | openssl x509 -noout -ocsp_uri 2>/dev/null`
## https://backreference.org/2010/05/09/ocsp-verification-with-openssl/
## links -dump 'https://crt.sh/?q=""'
echo so this is implemented yet... Check for certificate revocation
;;

-s)
serial=`echo "$certificate" | openssl x509 -noout -serial 2>/dev/null | sed -n 's/ *serial=*//p'`

if [ -n "$serial" ]
then
    echo $serial
fi
;;

-t)
thumbprint=`echo "$certificate" | openssl x509 -noout -fingerprint 2>/dev/null | sed -n 's/ *SHA1 Fingerprint=*//p'`

if [ -n "$thumbprint" ]
then
    echo $thumbprint
fi
;;

-x)
sanlist=`echo "$certificate" | openssl x509 -text 2>/dev/null | grep DNS: | sort -u`

if [ -n "$sanlist" ]
then
    echo $sanlist
fi
;;

*)
echo "usage: $0 [-c san | -d|-i|-p|-s|-t|-x] hostname port sni"
#echo "    -c <san> Check host is valid for certificate, e.g. autodiscover.example.com "
echo "    -d Show valid days remaining"
echo "    -i Show Issuer"
echo "    -p Show Primay Subject of certificate, e.g. www.example.com"
echo "    -s Show SSL serial number"
echo "    -t Show SHA1 Thumbprint"
echo "    -x Show extra SAN values, e.g. dev.example.com"
;;
esac
