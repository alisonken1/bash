# DO NOT RUN THIS BY ITSELF
# It is designed to be sourced by originating file
#
__name__="facts2archive"
__version__="0.2"
__release__="BETA"

if [ "${__status__}" != "RUN" ]; then
    echo ${__name__} ${__version__} ${__release__}
else
    #
    # Variables uses
    # dirReports    = Archive directory
    # t             = EXTREMELY temporary holding value
    # fileTmp       = Temp file name while processing
    # tDate[]       = Date string (MM/DD/YY) converted to array
    # tHead[]       = First 3 lines of report split into tokens
    # tHeadCount    = Number of indices in tHead array
    # tTime[]       = Report time split into tokens
    # tFileName     = Final name of report file
    #
    #
    dbg ${dbg_INFO} "Starting ${__name__}"
    #
    # Testing purposes - remove when publishing
    cp ${fileTmp} ${dirBase}/tmp/archive

    # Get the first 2 lines of the report, split them into
    # an array
    declare -a tHead=( $(head -n 2 ${fileTmp} | stripM1) )
    tHeadCount=${#tHead[*]}
    dbg ${dbg_DATA} "tHead='${tHead[*]}'"
    if [ ${#tHead[*]} -lt 2 ] ; then
        # Not an archival report
        dbg ${dbg_ERROR} "Not a valid report"
    else
        # Test for special case of deposit ticket
        if [ "${tHead[9]} ${tHead[10]}" = "DEPOSIT TICKET" ]; then
           tHead=( $(head -n 5 ${fileTmp} | stripM1) )
        fi

        t=0
        while [ ${t} -lt ${tHeadCount} ]; do
           dbg ${dbg_DATA} "tHead[${t}] = ${tHead[${t}]}"
           t=$(( ${t} + 1 ))
        done

        # tHead[1] = Date (MM/DD/YY)
        # tHead[3] = Module (eg. SOR310)
        # tHead[last-4] = register number or garbage

        # Get the time properly formatted

        declare -a tTime=( $(echo ${tHead[ $((tHeadCount - 2)) ]} | sed -e 's/:/ /g') )
        dbg ${dbg_DATA} "tTime=${tTime}"
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
        declare -a tDate=( $(echo "${tHead[1]}" | sed -e 's/\// /g') )

        # Create the filename for report

        # <Report Module Name>_<Register number>_<Date YYYYMMDD> [ <Sequence number .NNN> ]
        # Check for screwball deposit ticket report
        if [ "${tHead[9]} ${tHead[10]}" = "DEPOSIT TICKET" ]; then
           tFileName="${tHead[3]}_${tHead[15]}_20${tDate[2]}${tDate[0]}${tDate[1]}"
        else
           tFileName="${tHead[3]}_${tHead[$(( $tHeadCount - 4 ))]}_20${tDate[2]}${tDate[0]}${tDate[1]}"
        fi
        tYear=20${tDate[2]}
        if [ "${tFileName}" = "__20" ] || [ "${tYear}" == "20" ]; then
           # Not a proper report - delete
           dbg ${dbg_ERROR} "Not a valid report - exiting"
        else
            # Variables for proper placing of file in archive tree
            tMonth=${tDate[0]}

            # Check for directory structure
            RPTDIR="${dirReports}/${tYear}/${tMonth}"
            if [ ! -d "${RPTDIR}" ]; then
               {   mkdir -p "${RPTDIR}"
                   chgrp users "${RPTDIR}"
                   chmod 775 "${RPTDIR}"
               } 2>/dev/null
            fi
            if [ ! -d "${RPTDIR}" ] ; then
                dbg ${dbg_ERROR} "Unable to create directory ${RPTDIR}"
                dbg ${dbg_ERROR} "Cannot save report"
            else
                # Check for new directory needed
                # Check if the report exists
                # Add a sequence number if needed
                if [ -f "${RPTDIR}/${tFileName}" ]; then
                   tFileName=${tFileName}.`getSeq "${RPTDIR}/${tFileName}"`
                fi

                # Period check register mod (change MM/YY to MM_DD for filename)
                tFileName=$(echo ${tFileName} | sed -e 's/\//_/g')

                mv ${fileTmp} ${RPTDIR}/${tFileName} >&2
                dbg ${dbg_INFO} "Moved ${fileTmp} to ${RPTDIR}/${tFileName}"
            fi
        fi
    fi
fi
