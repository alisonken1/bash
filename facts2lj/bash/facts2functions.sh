# DO NOT RUN THIS BY ITSELF
# It is designed to be sourced by originating file
__name__="facts2functions"
__version__="0.3"
__release__="BETA"

if [ "${__status__}" != "RUN" ]; then
    echo ${__name__} ${__version__} ${__release__}
else
    #
    # Common variables and routines for facts printing
    #
    # ======= WARNING ======== WARNING ======= WARNING =====
    #
    # Several functions use sed with a byte check (i.e., ^M) and
    # most text editors other than vi WILL mangle the
    # sed script. DO NOT USE A TEXT EDITOR THAT WILL MANGLE ^M!!!
    #
    # ====== WARNING ========= WARNING ======= WARNING =====
    #
    # ======================================================
    # dbg()          - Output debugging info to stderr
    # crunch()       - Remove leading/trailing spaces
    # get_right()    - Strip trailing spaces/newlines
    # getFileName()  - Strip path info and return filename
    # getNext()      - Returns the next line of input
    # getPrevMonth() - Return the previous month number
    # getSeq()       - Return the next number in a sequence (up to 999)
    # getTempFile()  - Append [a-z] to $1 to get unique filename
    # printMe()      - Send print job to printer
    # rmTmpFiles()   - Remove temp files ${filePS} ${fileItems} ${fileWork} ${fileTest}
    # stripM()       - Remove ^M from line
    # stripM1()      - Cconvert & to %, [^M#] to <space>
    # stripMe()      - Remove extra \n\r\f characters and outside whitespace
    # ======================================================
    #
    # =========  Directory/File defines ====================
    echo 'Loading common variables' >&2
    # common variables
    # dirBase="/facts" # Define in each script
    # dirScrips="${dirBase}/bash" # Define in each script
    export dirReports="${dirBase}/REPORTS"
    export dirTemp="${dirBase}/tmp"
    export dirWork="${dirBase}/work"
    export webBASE="/var/www"
    export webCGI="${WEBBASE}/cgi-bin"
    export webPAGE="${WEBBASE}/htdocs"
    export webRPTINDX="${WEBCGI}/mkrptindex.sh"
    # =========  Directory/File defines ====================
    #
    # ========= Debug defines ==============================
    export dbg_NONE=0
    export dbg_FATAL=$(( ${dbg_NONE} + 1 ))
    export dbg_ERROR=$(( ${dbg_FATAL} + 1 ))
    export dbg_INFO=$(( ${dbg_ERROR} +1 ))
    export dbg_SUB=$(( ${dbg_INFO} + 1 ))
    export dbg_LOOP=$(( ${dbg_SUB} + 1 ))
    export dbg_DATA=$(( ${dbg_LOOP} + 1 ))
    export dbg_VAR=$(( ${dbg_DATA} + 1 ))
    export dbg_ALL=99
    export dbgLevel=${dbg_INFO}
    declare -a dbgTags
    dbgTags[${dbg_FATAL}]="FATAL : "
    dbgTags[${dbg_ERROR}]="ERROR : "
    dbgTags[${dbg_INFO}]="INFO  : "
    dbgTags[${dbg_SUB}]="SUB   : "
    dbgTags[${dbg_LOOP}]="LOOP  : "
    dbgTags[${dbg_DATA}]="DATA  : "
    dbgTags[${dbg_VAR}]="VAR   : "
    export dbTags
    # ========= Debug defines ==============================
    #
    # ========= Printer defines ============================
    # Printer defined by $0 (symlink to this file for printer queue)
    export lpPrinter="$(basename ${0} | cut -d. -f1)"
    export lpCommand="/usr/bin/lp -d ${lpPrinter}"
    export lpStatus="/usr/bin/lpq -P ${lpPrinter}"
    export lpOpts='-s'
    # ========= Printer defines ============================
    #
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

    echo 'Loading stripMe()' >&2
    stripMe() { echo -ne ${@}; }

    echo 'Loading dbg()' >&2
    dbg() {
      # $1 = debug level for output
      # $2 $N = line to print
      local dbgz dbglvl zz
      dbglvl=${1} ; shift
      [ ${dbglvl} -eq ${dbg_NONE} ] && return
      [ ${dbglvl} -gt ${dbgLevel} ] && return
      zz=${@}
      case ${dbglvl} in
      ${dbg_DATA} | ${dbg_VAR} )
        # Indent input line
        echo "${dbgTags[$dbglvl]}     ${zz}" >&2
        ;;
      * )
        # Just dump line
        echo "${dbgTags[$dbglvl]}${zz}" >&2
        ;;
      esac
    }

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
      echo -n "${tFile}"
      [ "${1}" == "${tFile}" ] && return 1 # All extensions already used
      return
    }

    # ===================
    echo "Loading rmTmpFiles()" >&2
    rmTmpFiles() {
      dbg ${dbg_SUB} "rmTmpfiles() called"
      # Remove temporary files before exiting
      dbg ${dbg_INFO} "Cleaning temporary files ${filePre} ${filePS} ${fileItems} ${fileWork} ${fileTmp} ${fileTest}"
      rm ${filePre} ${fileTmp} ${filePS} ${fileItems} ${fileWork} ${fileTmp} ${fileTest}>/dev/null 2>&1
    }

    # ===================
    echo "Loading getNext()"
    getNext() {
      # Read the next line of input
      # Return ${string} on stdout, Return ${?} of read status
      # Strips only \f\n\r out of string
      dbg ${dbg_SUB} "getNext() 1=${1} 2=${2} called"
      local gnzz gnss gndt IFS gnskip gncount gnread
      IFS="/f/n/r"
      if [ "${1::5}" == "BLANK" ] ; then
        gnskip=1 # Skip $2 number of lines
      elif [ "${1::4}" == "SKIP" ] ; then
        gnskip=2 # Skip only blank lines
      else
        gnskip=0
      fi # ${1} checks
      # Use the largest section as the maximum count if skipping lines
      # and no number given
      gncount=${2:-$invItemEnd}
      dbg ${dbg_VAR} "gnskip=${gnskip} gncount=${gncount}"
      gnread=0
      for (( i=1; i<=${gncount}; i++ )) ; do
        read gnzz
        gnss=$?
        echo "${gnzz}">&7
        case ${gnss} in

          0)
            # Good read
            dbg ${dbg_LOOP} "READ: ${gnzz}"
            ;;
          1)
            # EOF
            dbg ${dbg_LOOP} "READ: EOF detected"
            export pgEOF=1
            gnread=${gncount}
            break
            ;;
          *)
            # Error
            dbg ${dbg_ERROR} "READ: ERROR CODE ${ss} - Exiting"
            exit
            ;;
        esac
        if [ ${gnskip} -eq 0 ] ; then
          dbg ${dbg_LOOP} "getNext() returning 1 line"
          break # Read one line only
        elif [ ${gnskip} -eq 1 ] ; then
          zz=$(echo ${gnzz})
          [ ${#zz} -gt 2 ] && break # Return on first non-blank line
        fi # ${gnskip} -eq 1
        gnread=$(( ${gnread} + 1 ))
      done
      echo -n "${gnzz}" | tr -d '\f\n\r'  # Return line to caller on stdout
      return ${gnread}  # Exit with number of lines read
    } # getNext()
    # ===================
    printMe () {
      # ${1} is the file to print
      dbg ${dbg_SUB} "printMe() called"
      ${lpStatus} ${lpPrinter} >/dev/null 2>&1
      if [ $? -ne 0 ] ]; then
          dbg ${dbg_ERROR} "Printer ${1} not found - not printing"
      else
          dbg ${dbg_INFO} "Finished conversion run - sending ${1} to printer ${lpPrinter}"
          dbg ${dbg_INFO} "Print command: '${lpCommand} ${lprPrinter} ${lpOpts} ${1}'"
          ${lpCommand} ${lpPrinter} ${lpOpts} ${1}
          sleep 3
      fi
      return
    }
fi
