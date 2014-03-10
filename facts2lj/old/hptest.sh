#!/bin/sh
# $1 = printer
# $2 = font { COURIER | HELV | ROMAN | GOTHIC | ELITE }
# $3 = CPI { 12 | 16 }
# $4 = MODE { DRAFT | LQ }

tmpfile=/tmp/hptest.print
EOF=""

EJECT="&l0H"

LINE="(s0T"
COURIER="(s3T"
HELV="(s4T"
ROMAN="(s5T"
GOTHIC="(s6T"
ELITE="(s8T"
# $2 = font
case $2 in
   LP)
      FONT=${LINE}
      ;;
   HELV)
      FONT=${HELV}
      ;;
   ROMAN)
      FONT=${ROMAN}
      ;;
   GOTHIC)
      FONT=${GOTHIC}
      ;;
   ELITE)
      FONT=${ELITE}
      ;;
   *)
      FONT=${COURIER}
esac
echo -n ${FONT} >${tmpfile}

CPI10="(s10H"
CPI12="(s12H"
CPI16="(s16H"
# $3 = CPI
if [ t$3 == "t16" ] 
then
   echo -n ${CPI16} >>${tmpfile}
elif [ t$3 == "t10" ]
then
   echo -n ${CPI10} >>${tmpfile}
else
   echo -n ${CPI12} >>${tmpfile}
fi

LPI6="&l6D"
LPI8="&l8D"
[ "t$3" == "t16" ] && echo -n ${LPI8} >>${tmpfile} || echo -n ${LPI6} >>${tmpfile}

# $4 = mode
DRAFT="(s0Q"
LQ="(s2Q"
[ t$4 == "tDRAFT" ] && echo -n ${DRAFT} >>${tmpfile} || echo -n ${LQ} >>${tmpfile}

# Get the stdin
cat - >>${tmpfile}

# Output end-of-file
echo -n "${EOF}" >>${tmpfile}

# Send the output to the specified printer
lp -d $1 ${tmpfile} -o raw 2>>${tmpfile}.check

