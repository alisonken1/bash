#!/bin/bash +x

# Save printout as a text file
# Optionally send to printer designated by $0
#
# Root directory of setup
dirBase="/facts"
dirScripts="${dirBase}/bash"
myName="cdreports"

#
# Variables uses
# t		= EXTREMELY temporary holding value
# tReport	= Temp file name while processing
# tDate[]	= Date string (MM/DD/YY) converted to array
# tHead[]	= First 3 lines of report split into tokens
# tHeadCount	= Number of indices in tHead array
# tTime[]	= Report time split into tokens
# tFileName	= Final name of report file

# Source common functions
# options in functions that should be defined
#
# ${dirBase}	= base directory for reports/routines/etc.
# ${dirRpt}	= Directory to save reports
# ${LPR}	= Print program to send to
# ${LPROPT}	= Common options for print program ${LPR}

# Routines used
#
# func getSeq( /path/report_file_name )
#      return /path/report     (first time)
#             <sequence number 001-999>
#

source ${dirScripts}/functions.sh

# Save report to temp file
tReport="$( getTempFile '${dirTemp}/${myName}.$$' )"
tReport="${dirTemp}/${myName}.$$"
echo "Saving report as temp file ${tReport}" >&2
cat - >"${tReport}"
cp ${tReport} ${dirBase}/tmp/cdreports/
echo "Checking 'head -n 10 ${tReport}'" >&2
head -n 5 ${tReport} >&2
# See how wide the printout is
# The things you have to work around
declare -a tls=$(
  head -n 10 ${tReport} | while read zz ; do
    tln=$( echo ${zz} | sed -e 's///g' )
    echo "Checking tln='${tln}'" >&2
    echo "Checking \${#tln}=${#tln}" >&2
    echo ${#tln}
  done
)

export tlSize=0
for i in ${tls[@]} ; do
  [ ${i} -gt ${tlSize} ] && tlSize=${i}
done
echo "tlSize=${tlSize}" >&2

# Check for which font size to use
if [ ${tlSize} -gt 140 ]; then
  LPROPT="${LPROPT} -o cpi=18 -o lpi=8 -o landscape"
elif [ ${tlSize} -gt 100 ]; then
  LPROPT="${LPROPT} -o cpi=18 -o lpi=8 -o page-top=36"
elif [ ${tlSize} -gt 97 ] ; then
  LPROPT="${LPROPT} -o cpi=14 -o lpi=6 -o page-top=25"
else
  LPROPT="${LPROPT} -o cpi=12 -o lpi=6 -o page-top=36"
fi

# See if we were called as a link for printing
if [ -L $0 ] ; then
  t="$(getFileName $0)"
  declare -a tp=( $(echo ${t} | sed -e 's/\./ /g') )
  tc=$(( ${#tp[*]} -1 ))
  if [ "${tp[ ${#tc} ] }" == "sh" ] ; then
    tc=$(( ${tc} - 1 ))
  fi
  tPrinter=${tp[${tc}]}
  if [ "${tPrinter}" == "checks" ] ; then
    LPROPT='-o raw'
    td=$( date "+%Y%j%H%M" )
    tChecks="${dirTmp}/checks-${td}"
    echo "Saving check printout to ${tChecks}" >&2
    cp ${tReport} ${tChecks} >&2
  elif [ "${tPrinter}" == "hl-2040" ] ; then
    LPROPT="${LPROPT} -o media=Letter -o page-left=28"
  fi
  echo "Called as ${tPrinter}: Sending output to ${LPR} ${tPrinter} ${LPROPT}" >&2
  ${LPR} ${tPrinter} ${LPROPT} ${tReport} >&2
  if [ "${1}" == "NOARCHIVE" -o "${MyName}" == "${t}" -o "${tPrinter}" == "checks" ] ; then
    echo 'Not archiving printout' >&2
    rm ${tReport} >&2
    exit
  fi
fi

# Get the first 2 lines of the report, split them into
# an array
# ======== WARNING WARNING WARNING =======
# If not using vi, make sure the sed statement reads:
#    sed -e 's/[^M#]/  /g'
# to remove trailing newlines. ^M is single byte in vi using <ctl>vM
declare -a tHead=( `head -n 2 ${tReport} | sed -e 's/[#]/ /g' -e 's/\&/%/g' `)
tHeadCount=${#tHead[*]}

# Test for special case of deposit ticket
# ======== WARNING WARNING WARNING ========
# If not using vi, make sure the sed statement reads:
#    sed -e 's/[^M#]/  /g'
# to remove trailing newlines. ^M is single byte in vi using <ctl>vM
#
if [ "${tHead[9]} ${tHead[10]}" = "DEPOSIT TICKET" ]; then
   tHead=( `head -n 5 ${tReport} | sed -e 's/[#]/ /g' -e 's/\&/%/g'` )
fi

t=0
while [ ${t} -lt ${tHeadCount} ]; do
   echo "tHead[${t}] = ${tHead[${t}]}" >&2
   t=$(( ${t} + 1 ))
done

# tHead[1] = Date (MM/DD/YY)
# tHead[3] = Module (eg. SOR310)
# tHead[last-4] = register number or garbage

# Get the time properly formatted

declare -a tTime=( `echo ${tHead[ $((tHeadCount - 2)) ]} | sed -e 's/:/ /g'` )
echo "tTime=${tTime}" >&2
if [ -n "$( echo ${tTime} | tr -d [:alpha:] | tr -d [:punct:] )" ] ; then
  if [ "${tHead[ $(( ${tHeadCount} - 1 )) ]}" = "PM" ]; then
     # Convert to 24hr format if between 1pm and 11:59pm
     tTime[0]=$(( ${tTime} + 12 ))
  elif [ "${tTime[0]}" -lt "10" ]; then
     # Add a leading 0 for 1am to 9am
     tTime[0]="0${tTime[0]}"
  fi
fi
# Get the date
declare -a tDate=( `echo "${tHead[1]}" | sed -e 's/\// /g'` )

# Create the filename for report

# <Report Module Name>_<Register number>_<Date YYYYMMDD> [ <Sequence number .NNN> ]
# Check for screwball deposit ticket report
if [ "${tHead[9]} ${tHead[10]}" = "DEPOSIT TICKET" ]; then
   tFileName="${tHead[3]}_${tHead[15]}_20${tDate[2]}${tDate[0]}${tDate[1]}"
else
   tFileName="${tHead[3]}_${tHead[$(( $tHeadCount - 4 ))]}_20${tDate[2]}${tDate[0]}${tDate[1]}"
fi
if [ "${tFileName}" = "__20" ]; then
   # Not a proper report - delete
   rm ${tReport}
   echo "Not a valid report - exiting" >&2
   exit
fi

# Variables for proper placing of file in archive tree
tYear=20${tDate[2]}
tMonth=${tDate[0]}

# Check for directory structure
if [ ! -d "${dirReports}/${tYear}/${tMonth}" ]; then
   mkdir -p "${dirReports}/${tYear}/${tMonth}"
   chgrp users "${dirReports}/${tYear}/${tMonth}"
   chmod 775 "${dirReports}/${tYear}/${tMonth}"
fi
RPTDIR="${dirReports}/${tYear}/${tMonth}"

# Check for new directory needed
# Check if the report exists
# Add a sequence number if needed
if [ -f "${RPTDIR}/${tFileName}" ]; then
   tFileName=${tFileName}.`getSeq "${RPTDIR}/${tFileName}"`
fi

# Period check register mod (change MM/YY to MM_DD for filename)
tFileName=`echo ${tFileName} | sed -e 's/\//_/g'`

mv ${tReport} ${RPTDIR}/${tFileName} >&2
echo tFileName = ${tFileName} >&2
