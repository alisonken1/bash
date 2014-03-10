#!/bin/bash

TMPFILE=/facts/tmp/facts_receipt.$$
LOGFILE=/facts/tmp/facts_receipt.log
cat ->$TMPFILE

PQUEUE=$1
if [ $(lpr -P ${PQUEUE} >/dev/null 2>&1 ) ] ; then
  echo "FACTS: Invalid print queue $PQUEUE specified" >>$LOGFILE
  exit 1
fi
cat $TMPFILE | lpr -o raw -P $PQUEUE
#echo "FACTS: Sent job to printer $PQUEUE" >>$LOGFILE
rm $TMPFILE
