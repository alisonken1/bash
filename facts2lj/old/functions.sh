#!/bin/bash

# Common variables and routines for facts printing
#
# ======= WARNING ======== WARNING ======= WARNING =====
#
# Several functions use sed with a byte check (i.e., ^M) and
# most text editors other than ones like vi WILL mangle the
# sed script. DO NOT USE A TEXT EDITOR THAT WILL MANGLE ^M!!!
#
# ====== WARNING ========= WARNING ======= WARNING =====

echo 'Loading common variables' >&2
# common variables
dirBase="/facts"
dirReports="${dirBase}/REPORTS"
dirTemp="${dirBase}/tmp"
dirWork="${dirBase}/work"
dirScripts="${dirBase}/bash"
#BASEDIR=/facts
#RPTDIR=${BASEDIR}/REPORTS
#RPTBASE=${BASEDIR}/REPORTS

webBASE="/var/www"
webCGI="${WEBBASE}/cgi-bin"
webPAGE="${WEBBASE}/htdocs"
webRPTINDX="${WEBCGI}/mkrptindex.sh"

LPR="/usr/bin/lp -d"
#LPR="/usr/bin/lpr -P"
LPROPT="-s"
#LPROPT="-s -o raw"

#
# #################################################### #
#     WARNING == WARNING == WARNING == WARNING         #
# sed commands that appear to be split onto several    #
# lines have embedded ^M characters and need to be     #
# edited with a binary style text editor like VI.      #
# If so, edit in VI and make sure the sed command      #
# looks like the following:                            #
#              sed -e 's/[^M]//g'                      #
# Text editors like kate WILL mangle the ^M character  #
#     WARNING == WARNING == WARNING == WARNING         #
# #################################################### #
#
echo 'Loading stripM()' >&2
stripM() { sed -e 's///g'; }

echo 'Loading stripM1()' >&2
stripM1() { sed -e 's/[#]/ /g' -e 's/\&/%/g'; }

echo 'Loading crunch()' >&2
crunch() { echo "$*"; }

echo 'Loading get_right()' >&2
get_right() {
  # echo "'${1}'" >&2
  grChk=${*}
  if [ ${#grChk} -lt 1 ]; then
    echo ''
  else
    for (( tc=${#grChk}-1 ; $tc > 0 ; tc=$tc-1 )) ; do
      # echo "Checking '${grChk:$tc:1}': '${grChk:0:$tc}'" >&2
      if [ "${grChk:$tc:1}" != " " ] ; then
        tc=$(($tc + 1))
        break
      fi
    done
    # echo "tc=${tc}"
    echo "'${grChk:0:$tc}'"
  fi
}

echo 'Loading getPrevMonth()' >&2
getPrevMonth() { 
   [ $1 -lt 1 -o $1 -gt 12 ] && return 1
   m="  12 1 2 3 4 5 6 7 8 91011"
   echo -n ${m:$(($1*2)):2}
}

echo 'Loading getFileName()' >&2
getFileName() {
   [ $# -lt 1 ] && return
   declare -a myPath=( $(echo $1 | sed -e 'y/\// /') )
   t=$(( ${#myPath[*]} - 1 ))
   echo ${myPath[$t]}
}

echo 'Loading getSeq()' >&2
getSeq() {
   [ $# -lt 1 ] && return
   # $1     = filename to sequence
   # [ $2 ] = highest number to check
   # [ $3 ] = starting number

   lcount=20    # Maximum number to check
   fcount=1     # Minimum number to check
   # Get range to check
   if [ $# -gt 1 ]; then
      lcount=$2
   fi
   if [ $# -gt 2 ]; then
      fcount=$3
   fi

   seq=$fcount
   while [ $seq -ne $lcount ]; do
      if [ $seq -lt 10 ]; then
         chk=00$seq
      elif [ $seq -lt 100 ]; then
         chk=0$seq
      else
         chk=$seq
      fi
      if [ ! -f $1.$chk ]; then
         break
      fi
      seq=$(($seq + 1))
   done
   echo ${chk}
}

echo 'Loading getTempFile()' >&2
getTempFile() {
  tFile="${1}"
  [ -z "${tFile}" ] && {
    echo "getTempFile(): No file to check - returning"
    return 1
  }
  # Start with file ${1} return a unique filename using the alphabet
  # Will return the original file if all letters are already taken
  for i in '' a b c d e f g h i j k l m n o p q r s t u v w x y z ; do
    [ -e "${tFile}${i}" ] && continue
    tFile="${tFile}${i}"
    break
  done
  echo -n "$tFile"
  return
}

