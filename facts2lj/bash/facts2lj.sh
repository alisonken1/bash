#!/bin/bash
#
#
# Entry point for facts2lj scripts.
# Called by F.A.C.T.S. via pipe.
#
# Check input for what type of printout and source the appropriate script
# for output to printer ($0 is link for printer queue), with option
# to save to REPORTS directory for archiving.
#
export dirBase="/facts"
export dirScripts="${dirBase}/bash"
#
export __name__="facts2lj"
export __version__="0.3"
export __release__="BETA"
export __status__="RUN"
declare -a  __scripts__
__scripts__[0]="facts2functions"
__scripts__[1]="facts2archive"
__scripts__[2]="facts2invoice"
export __scripts__
#
# Test for options
case ${1} in
-v|--version)
    unset __status__
    echo ${__name__} ${__version__} ${__release__}
    for i in ${__scripts__[*]}; do
        ${dirScripts}/${i}.sh
    done
    exit
    ;;
esac
echo "${__name__} ${__version__} starting initial run" >&2
echo "Sourcing ${dirScripts}/facts2functions.sh" >&2
source ${dirScripts}/facts2functions.sh
# At this point the rest of the functions and variables should be useable
#
#==================================================
# Save report to temp file

export fileTmp="$( mktemp ${dirTemp}/${__name__}.XXXXXX )"
zz=$?
if [ ${zz} -ne 0 ]; then
    dbg ${dbg_FATAL} "Cannot create temporary file!!!! Inodes full?"
    dbg ${dbg_FATAL} "Exiting mktemp code ${zz}"
    rmTmpFiles
    exit ${zz}
fi
dbg ${dbg_INFO} "Saving to ${fileTmp}"
cat - >"${fileTmp}"
zz=$?
[ ${zz} -ne 0 ] && {
        dbg ${dbg_FATAL} "Cannot save to ${fileTmp}!!!! Filesystem full?"
        dbg ${dbg_FATAL} "Exiting mktemp code ${zz}"
        rmTmpFiles
        exit ${zz}
}

# =================================================
# Check for special processing outputs
case ${lpPrinter} in
archive)
    # Archive only
    dbg ${dbg_INFO} "Sending data to archive"
    source ${dirScripts}/facts2archive.sh
    ;;
*)
    # Test for invoice first
    dbg ${dbg_INFO} "Calling invoice"
    export dbgLevel=${dbg_ALL}
    source ${dirScripts}/facts2invoice.sh
    ;;
esac

rmTmpFiles
