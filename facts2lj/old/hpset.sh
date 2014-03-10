#!/bin/sh
# This file is just for printing to the Apple LaserWriter in HP mode
# $1 is the only requirement, the others are for testing
# $1 = printer
# $2 = font { COURIER * | LINE } or RAW to skip rest
# $3 = CPI { 5 | 10 | 12 * | 16 }
# $4 = MODE { DRAFT | LQ * }
# $5 = LPI { 6 * | 8 }

if [ t$1 == t-? -o t$1 = t? ]; then
      cat <<HERE

   Usage: $0 {output device} {font} {cpi} {mode} {lpi}

          {output device} = filename or /dev/ output
          {font}          = COURIER* | LINE
          {cpi}           = 5 | 10 | 12* | 16
          {mode}          = DRAFT | LQ*
          {lpi}           = 6* | 8

    Note: * indicates default

HERE
   exit
fi

BASE_DIR="/facts"
tmpfile=${BASE_DIR}/tmp/printout.$$
lockfile=${BASE_DIR}/tmp/printout..lock.${1}
trap 'rm -rf ${tmpfile} ${lockfile} 2>/dev/null' 0 1 2 3 15

# Codes for setting typeface
# $2 = font
case $2 in
   LP)
      OPTIONS="${OPTIONS} -o font=courier"
      ;;
   *)
      OPTIONS="${OPTIONS} -o font=courier"
esac

# Codes for setting pitch
CPI5='&k1S'
CPI10='&k0S'
CPI12='&k4S'
CPI16='&k2S'
# $3 = CPI
if [ t$3 == "t16" ]; then
   OPTIONS="${OPTIONS} -o cpi=17"
elif [ t$3 == "t10" ]; then
   OPTIONS="${OPTIONS} -o cpi=10"
elif [ t$3 == "t5" ]; then
   OPTIONS="${OPTIONS} -o cpi=5"
else
   OPTIONS="${OPTIONS} -o cpi=12"
fi

# Codes for lines per inch
LPI6='&l6D'
LPI8='&l8D'
[ "t$5" == "t8" ] && OPTIONS="${OPTIONS} -o lpi=8" || OPTIONS="${OPTIONS} -o cpi=6"

# $4 = mode
DRAFT='(s0Q'
LQ='(s2Q'
#[ t$4 == "tDRAFT" ] && TMPSETUP=${TMPSETUP}${DRAFT} || TMPSETUP=${TMPSETUP}${LQ}

case $2 in
   raw)
      ;;
   RAW)
      ;;
   *)
   # Send the setup string
   #echo -n ${TMPSETUP} >${tmpfile}
esac

# Get the stdin
cat - >>${tmpfile}

# Output end-of-file
echo -n ${EOF} >>${tmpfile}

# Send the output to the specified printer
#lp -d ${outfile} ${tmpfile} -o raw 2>/dev/null

while [ -e ${lockfile} ] ; do
   sleep 5
done

#if [ "t${LP}" == "tNO" ] ; then
#   touch ${lockfile}
#   cat ${tmpfile} >${outfile}
#else
   lpr -P ${outfile} ${OPTIONS} ${tmpfile} 2>/dev/null
   #lp -d ${outfile} -o raw ${tmpfile} 2>/dev/null
#fi

rm ${lockfile} >>/dev/null
#rm ${tmpfile} >>/dev/null
