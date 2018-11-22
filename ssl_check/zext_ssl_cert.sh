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

f=$1
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

case $f in
-d)
end_date=`openssl s_client -servername $servername -host $host -port $port -showcerts $starttls -prexit </dev/null 2>/dev/null |
          sed -n '/BEGIN CERTIFICATE/,/END CERT/p' |
          openssl x509 -text 2>/dev/null |
          sed -n 's/ *Not After : *//p'`

if [ -n "$end_date" ]
then
    end_date_seconds=`date '+%s' --date "$end_date"`
    now_seconds=`date '+%s'`
    echo "($end_date_seconds-$now_seconds)/24/3600" | bc
fi
;;

-i)
issue_dn=`openssl s_client -servername $servername -host $host -port $port -showcerts $starttls -prexit </dev/null 2>/dev/null |
          sed -n '/BEGIN CERTIFICATE/,/END CERT/p' |
          openssl x509 -text 2>/dev/null |
          sed -n 's/ *Issuer: *//p'`

if [ -n "$issue_dn" ]
then
    issuer=`echo $issue_dn | sed -n 's/.*CN=*//p'`
    echo $issuer
fi
;;
-r)
## We need the thumbprint to query crt.sh
thumbprint=`openssl s_client -servername $servername -host $host -port $port -showcerts</dev/null 2>/dev/null |                                                    sed -n '/BEGIN CERTIFICATE/,/END CERT/p' |                                                                                                             openssl x509 -noout -fingerprint 2>/dev/null |                                                                                                         sed -n 's/ *SHA1 Fingerprint=*//p'`

#revoked=$("openssl verify -crl_check -CAfile <(OLDIFS=$IFS; IFS=':' certificates=$(openssl s_client -connect $servername:$port -showcerts -tlsextdebug -tls1 2>&1 </dev/null | sed -n '/-----BEGIN/,/-----END/ {/-----BEGIN/ s/^/:/; p}'); for certificate in ${certificates#:}; do echo $certificate; done; IFS=$OLDIFS; openssl s_client -connect $servername:$port 2>&1 < /dev/null | sed -n '/-----BEGIN/,/-----END/p' | openssl x509 -noout -text | grep -m 1 URI:.*\.crl | sed 's/^.*URI://g' | xargs curl -s | openssl crl -inform DER -outform PEM) <(openssl s_client -connect $servername:$port 2>&1 < /dev/null | sed -n '/-----BEGIN/,/-----END/p'"))

echo $revoked

if [ -n "$thumbprint" ]
then
## do openssl browser emualtion here with thumbprint
echo Not implemented
fi

ocspurl=`openssl s_client -servername $servername -host $host -port $port -showcerts</dev/null 2>/dev/null |                                                    sed -n '/BEGIN CERTIFICATE/,/END CERT/p' |                                                                                                             openssl x509 -noout -ocsp_uri 2>/dev/null`
## https://backreference.org/2010/05/09/ocsp-verification-with-openssl/
## links -dump 'https://crt.sh/?q="$tumbprint"'
echo so this is implemented yet... Check for certificate revocation
;;
-s)
serial=`openssl s_client -servername $servername -host $host -port $port -showcerts</dev/null 2>/dev/null |                                                        sed -n '/BEGIN CERTIFICATE/,/END CERT/p' |                                                                                                             openssl x509 -noout -serial 2>/dev/null |                                                                                                              sed -n 's/ *serial=*//p'`

if [ -n "$serial" ]
then
    echo $serial
fi
;;
-t)
thumbprint=`openssl s_client -servername $servername -host $host -port $port -showcerts</dev/null 2>/dev/null |                                                    sed -n '/BEGIN CERTIFICATE/,/END CERT/p' |                                                                                                             openssl x509 -noout -fingerprint 2>/dev/null |                                                                                                         sed -n 's/ *SHA1 Fingerprint=*//p'`

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
