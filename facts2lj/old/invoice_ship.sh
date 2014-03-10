#!/bin/bash

# Check if we send to windows printer or linux printer

SMBCLIENT="/usr/bin/smbclient -N"
SMBSERVER=shipping
PRINTER_WIN=invoice
PRINTER_LINUX=invoice
TMPFILE=/tmp/invoice_ship.$$

cat - >$TMPFILE
if [ $($SMBCLIENT -L shipping >/dev/null 2>&1 ; echo $?) -eq 0 ] ; then
  PQ=$PRINTER_WIN
else
  PQ=$PRINTER_LINUX
fi

lp -o raw -d $PQ $TMPFILE >/dev/null 2>/dev/null
sleep 2
rm $TMPFILE
