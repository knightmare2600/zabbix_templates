#!/bin/bash

#------------------------------------------------------------------------------#
# This script renew a 3CX let's encrypt SSL certificate.                       #
#                                                                              #
# Created: 08 Jan 2019  Robert McLay      Initial version                      #
# Updated: 08 Jan 2019  Robert McLay      Pre-flight checks                    #
#------------------------------------------------------------------------------#

set -e

## Put folder name into a variable. TODO: Confirm what happen if there's more than one
INSTANCE=/var/lib/3cxpbx/Bin/nginx/conf/Instance1
LELIVE=/etc/letsencrypt/live/
RENEWED_DOMAINS=`find "$LELIVE" -mindepth 1 -maxdepth 1 -type d | cut -d\/ -f5`
PBX_INSTANCE="INSTANCE/$RENEWED_DOMAINS"-key.pem

## Pre-flight checks. Do binaries exist...?
for binary in certbot cp cut find service; do
  location=`/usr/bin/which "$binary" > /dev/null 2>&1`
  if [ "$?" -eq 1 ]; then
    /bin/echo "Error: $binary command not found in path... cannot proceed"
    /bin/echo
    exit 0
  fi
done

# Ensure our effective ID is 0 (i.e. root), otherwise exit as certbot will flub
if [[ $EUID -ne 0 ]]; then
  /bin/echo "You must have root permissions to renew certificates" 2>&1
  exit 1
## test if there are blank variables, so we don't hose workign certificates
elif [ "$RENEWED_DOMAINS" == '' ]; then
  /bin/echo 'Renewed domain variable returned blank. Please investigate'
  exit 1
elif [ "$PBX_INSTANCE" == '' ]; then
  /bin/echo 'PBX Current certificate. Please investigate'
  exit 1
elif [ ! -f "$INSTANCE/$RENEWED_DOMAINS-key.pem" ]; then
  /bin/echo "Private key $INSTANCE/$RENEWED_DOMAINS-key.pem not found exiting on safety grounds"
  exit 1
elif [ ! -f "$INSTANCE/$RENEWED_DOMAINS-crt.pem" ]; then
  /bin/echo "Certificate $INSTANCE/$RENEWED_DOMAINS-crt.pem not found exiting on safety grounds"
  exit 1
fi

## Sanity checks passed, let's renew the cert. Stopping nginx briefly to action the renewal
/usr/bin/certbot renew --pre-hook "service nginx stop"  --post-hook "service nginx start"

## Run through and renew each certificate.
for domain in $RENEWED_DOMAINS; do

  ## Back up old certificates in place
  /bin/echo "Backing up old Private key $INSTANCE/$RENEWED_DOMAINS-key.pem to $INSTANCE/$RENEWED_DOMAINS-key.pem.old"
  /bin/cp "$INSTANCE/$RENEWED_DOMAINS-key.pem" "$INSTANCE/$RENEWED_DOMAINS-key.pem.old"
  /bin/echo "Backing up old Certificate $INSTANCE/$RENEWED_DOMAINS-crt.pem to $INSTANCE/$RENEWED_DOMAINS-crt.pem.old"
  /bin/cp "$INSTANCE/$RENEWED_DOMAINS-crt.pem" "$INSTANCE/$RENEWED_DOMAINS-crt.pem.old"

  ## Test if new certificates & backups exist
  if [ ! -f "$LELIVE/$RENEWED_DOMAINS/privkey.pem" ]; then
    /bin/echo "New Private key $LELIVE/$RENEWED_DOMAINS/privkey.pem not found. Exiting on safety grounds"
    exit 1
  elif [ ! -f "$LELIVE/$RENEWED_DOMAINS/fullchain.pem" ]; then
    /bin/echo "New Certificate $LELIVE/$RENEWED_DOMAINS/fullchain.pem not found. Exiting on safety grounds"
    exit 1
  elif [ ! -f "$INSTANCE/$RENEWED_DOMAINS-key.pem.old" ]; then
    /bin/echo "Backup Private key $INSTANCE/$RENEWED_DOMAINS-key.pem.old not found. Exiting on safety grounds"
    exit 1
  elif [ ! -f "$INSTANCE/$RENEWED_DOMAINS-crt.pem.old" ]; then
    /bin/echo "Backup Certificate $INSTANCE/$RENEWED_DOMAINS-crt.pem.old not found. Exiting on safety grounds"
    exit 1
  fi

  ## Put new certificates in place
  /bin/echo "copy $LELIVE/$RENEWED_DOMAINS/privkey.pem to $INSTANCE/$RENEWED_DOMAINS-key.pem"
  /bin/cp "$LELIVE/$RENEWED_DOMAINS/privkey.pem to $INSTANCE/$RENEWED_DOMAINS-key.pem"
  /bin/echo "copy $LELIVE/$RENEWED_DOMAINS/fullchain.pem" "$INSTANCE/$RENEWED_DOMAINS-crt.pem"
  /bin/cp "$LELIVE/$RENEWED_DOMAINS/fullchain.pem" "$INSTANCE/$RENEWED_DOMAINS-crt.pem"

  # Apply proper file ownership/permissions for the daemon to read its cert & key
  /bin/echo "changing owndership of certificate and key to phonesystem:phonesystem as used by 3CX" 
  /bin/chown phonesystem:phonesystem "$INSTANCE/$RENEWED_DOMAINS-crt.pem" "$INSTANCE/$RENEWED_DOMAINS-key.pem"

## Now the new certificate is in place, do one final restart of nginx for the new certificate to take effect
/bin/echo "Reloading nginx service for new certificate to take effect"
/etc/init.d/nginx restart >/dev/null
done
