#! /bin/sh
#------------------------------------------------------------
# zext_ssl_cert.sh
# Script checks for number of days until certificate expires or the issuing authority
# depending on switch passed on command line.
#
#Based on script from aperto.fr (http://aperto.fr/cms/en/blog/15-blog-en/15-ssl-certificate-expiration-monitoring-with-zabbix.html)
#with additions by racooper@tamu.edu
#------------------------------------------------------------

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
    issuer=`echo $issue_dn | sed -n 's/.*CN=*//p'`
    echo $issuer
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

*)
echo "usage: $0 [-i|-d|-s] hostname port sni"
echo "    -i Show Issuer"
echo "    -d Show valid days remaining"
echo "    -s Show SSL serial number"
echo "    -t Show SHA1 Thumbprint"
;;
esac
