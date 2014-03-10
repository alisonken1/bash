#!/bin/bash
#
# CHANGES
# 20090213 - Fix for FACTS sometimes putting "DOLLARS" on a second line when
#            cash text line is too long
#
# ======== TEST CHECK ONE =========
#           Vendor  NTE   NTE ELECTORNICS, INC  02/12/07                040657
#
#
#  022154          249311        02/11/07        101.68        101.68         .00        101.68
#  022146          248466        02/11/07        159.98        159.98         .00        159.68
#  022144          248180        01/30/07       1472.45       1472.45         .00       1472.45
#
#
#
#
#                                                             1734.11    .00     1734.11
#
#
#
#                                                       02/12/07        040657      $1734.11
#
#          ONE THOUSAND SEVEN HUNDRED THIRTY FOUR AND 11/100
#          DOLLARS
#          NTE ELECTRONICS, INC
#          44 FARRAND STREET
#          BLOOMFIELD, NJ 07003
#
# ======== TEST CHECK ONE END =================
#
# ======== TEST CHECK TWO =========
#           Vendor  NTE   NTE ELECTORNICS, INC  02/12/07                040657
#
#
#  022154          249311        02/11/07        101.68        101.68         .00        101.68
#  022146          248466        02/11/07        159.98        159.98         .00        159.68
#  022144          248180        01/30/07       1472.45       1472.45         .00       1472.45
#
#
#
#
#                                                             1734.11    .00     1734.11
#
#
#
#                                                       02/12/07        040657      $1734.11
#
#          ONE THOUSAND SEVEN HUNDRED THIRTY FOUR AND 11/100 DOLLARS
#          NTE ELECTRONICS, INC
#          44 FARRAND STREET
#
#          BLOOMFIELD, NJ 07003
#
# ======== TEST CHECK TWO END =================
#
# NOTE: DOLLARS may be at the end of the cash line or prnted on the second
#       line
#

dirBase='/facts'
dirWork="${dirBase}/tmp"
prnFile="${dirWork}/check_$$.ps"
tmpFile="${dirWork}/check_$$.tmp"
lprPrinter='checks' # Currently Cherie's dot matrix printer
lprPrinter='laserjet2' # Cherie's laserjet downstairs
lprCommand="lpr -P ${lprPrinter} ${prnFile}"
chkSep='=============================='

# Temporary defines for testing
#prnFile="check_$$.ps"   # local esting
#tmpDump='check_dump.tmp'
#tmpFile='check_work.tmp' # Local testing
#lprPrinter='laserjet1' # Upstairs laserprinter
#lprCommand="lpr -P ${lprPrinter} ${prnFile}"

echo 'Starting cleanup run' >&2
#cat - | tr '\r' '\n' | tr -d '$' >${tmpDump} # Used for testing
{ # Condense FACTS screwball output so we can properly parse
    cat - | tr '\r' '\n' | tr -d '$' | while read -a newLine ; do
    #cat ${tmpDump} | while read -a newLine ; do # Testing line
        [ -z "${newLine[0]}" ] && continue
        if [ "${newLine[1]}" == 'Vendor' ] ; then
            # Should only be the first line that would have this
            unset newLine[0]
            echo -e "${chkSep}"
        elif [ "${newLine[0]}" == 'Vendor' ] ; then
            echo -e "${chkSep}"
        fi
        echo ${newLine[*]}
    done
} >${tmpFile}
tc=$( grep -c ^${chkSep} ${tmpFile} )
if [ ${tc} -lt 1 ] ; then
    echo "No checks to process - invalid input file?" >&2
    # rm ${tmpFile} 2>/dev/null
    exit
fi
echo "Number of checks to process: ${tc}" >&2
echo "Finished cleanup run - starting conversion run" >&2
{
    # Postscript header information
    cat <<HERE
%!PS
%
% 3-Section checks from Quill product DLM108 (1-part)
% Top    - Payee record
% Middle - Check
% Bottom - local record
%
%
% ================ Begin header information
%
% ================ Basic defines
%
/xMargin {36} def
/ptSize {10} def
/lnHeight {ptSize 1.2 mul} bind def
/pgTop {770} bind def
/pgRight {600} bind def
%
% Font defines
/fntLineHeader {/Courier-New findfont ptSize 0.80 mul scalefont} bind def
/fntLine {/Courier-New findfont ptSize scalefont} bind def
/fntCash {/Times-New-Roman findfont ptSize 1.25 mul scalefont} bind def
/fntText {/Times-New-Roman findfont ptSize scalefont} bind def
%
% Chck defines
%
% Check number by the preprinted check number
/chkXNumber
{ pgRight chkNumber stringwidth pop sub
  (Check number:    ) stringwidth pop sub
} bind def
/chkYNumber {500} bind def
% Check date
/chkXDate {415} bind def
/chkYDate {440} bind def
% Check amount
/chkXTotal {570} bind def
/chkYTotal {chkYDate} bind def
% PAY line amount (text of total)
/chkXCash {40} bind def
/chkYCash {405} bind def
% Address lines
/chkXAdx  {65} bind def
/chkYAdx1 {380} bind def
/chkYAdx2 {chkYAdx1 lnHeight sub} bind def
/chkYAdx3 {chkYAdx2 lnHeight sub} bind def
/chkYAdx4 {chkYAdx3 lnHeight sub} bind def
%
% Item listings box(es)
/boxLeft {20} bind def
/boxWidth {570} bind def
/boxTop {250} bind def
/boxHeight {200} bind def
/boxOffsetTop {510} bind def % Payee item listing box location
/boxOffsetBottom {10} bind def % Records item listing box location
/boxLine0 {boxTop boxOffset add lnHeight sub} bind def % Header line sep
/boxLine1 {boxLeft 60 add} bind def  % PO
/boxLine2 {boxLine1 80 add} bind def % Vendor invoice
/boxLine3 {boxLine2 60 add} bind def % Invoice date
/boxLine4 {boxLine3 95 add} bind def % Invoice total
/boxLine5 {boxLine4 95 add} bind def % Discount taken
/boxLine6 {boxLine5 65 add} bind def % Invoice total minus discount
/boxOffset {boxOffsetTop} def % Variable for routines
%
% Item listing positions
/itemX1 {boxLeft 5 add} bind def  % PO
/itemX2 {boxLine1 5 add} bind def % Vendor invoice
/itemX3 {boxLine2 5 add} bind def % Invoice date
/itemX4 {boxLine4 5 sub} bind def % Invoice amount - right justify
/itemX5 {boxLine5 5 sub} bind def % Invoice payment - right justify
/itemX6 {boxLine6 5 sub} bind def % Invoice discount - right justify
/itemX7 {boxLeft boxWidth add 5 sub} bind def % Invoice check amount - right
/itemY1 {boxTop boxOffset add lnHeight 2 mul sub } bind def
/itemY  {itemY1 lnHeight sub dup /itemY exch def } bind def
%/y {yPos leading sub dup /yPos exch def} bind def
%
% ================ Program routines
%
% Routine to concatenate 2 strings or 2 arrays together
% (string1) (string2) concatenate string3
% array1 array2 concatenate array3
/concatenate
{ %def
    dup type 2 index type 2 copy ne { %if
        pop pop
        errordict begin (concatenate) typecheck end
    }{ %else
        /stringtype ne exch /arraytype ne and {
            errordict begin (concatenate) typecheck end
        } if
    } ifelse
    dup length 2 index length add 1 index type
    /arraytype eq { array }{ string } ifelse
    % stack: arg1 arg2 new
    dup 0 4 index putinterval
    % stack: arg1 arg2 new
    dup 4 -1 roll length 4 -1 roll putinterval
    % stack: new
} bind def
%
% Routine to right justify data
/rJustify {dup stringwidth pop neg 0 rmoveto} bind def
%
% Draw a vertical line in the item entry box
/doBoxLine
{ newpath boxTop boxOffset add moveto 0 boxHeight neg rlineto stroke} bind def
%
% Draw the item box
/doBox
{ % Draw the box lines
  newpath boxLeft boxTop boxOffset add moveto boxWidth 0 rlineto
  0 boxHeight neg rlineto boxWidth neg 0 rlineto closepath stroke
  boxLine1 doBoxLine boxLine2 doBoxLine boxLine3 doBoxLine boxLine4 doBoxLine
  boxLine5 doBoxLine boxLine6 doBoxLine boxLeft boxLine0 moveto
  boxWidth 0 rlineto stroke
  % Add the header info
  itemX1 10 add boxLine0 3 add moveto (Our PO) show
  itemX2 7 add currentpoint exch pop moveto (Your Invoice) show
  itemX3 13 add currentpoint  exch pop moveto (Date) show
  itemX4 currentpoint exch pop moveto (Invoice Amount  ) rJustify show
  itemX5 currentpoint exch pop moveto (Amount Applied  ) rJustify show
  itemX6 currentpoint exch pop moveto (Discount  ) rJustify show
  itemX7 currentpoint exch pop moveto (Net Check Amount  ) rJustify show
  % Add the info just above the box
  boxLine2 30 sub boxTop 5 add boxOffset add moveto
  (Vendor: ) show acctAdx1 show
  boxLine6 boxTop 5  add boxOffset add moveto
  (Check: ) show chkNumber show
  % Add the info just below the box
  boxLeft boxTop boxOffset add boxHeight sub lnHeight sub moveto
  (Date: ) show chkDate show (  Account: ) show acctNumber show
  itemX4 currentpoint exch pop moveto (Detail totals:) rJustify show
  itemX5 currentpoint exch pop moveto itemInvoice rJustify show
  itemX6 currentpoint exch pop moveto itemDiscount rJustify show
  itemX7 currentpoint exch pop moveto itemCheck rJustify show
} bind def
%
% Print an item line listing
/doLine
{ pop % Remove the array count variable from the stack
  itemX7 currentpoint exch pop moveto rJustify show % Invoice check amount
  itemX6 currentpoint exch pop moveto rJustify show % Invoice discount
  itemX5 currentpoint exch pop moveto rJustify show % Invoice payment
  itemX4 currentpoint exch pop moveto rJustify show % Invoice amount
  itemX3 8 add currentpoint exch pop moveto show % Invoice date
  itemX2 currentpoint exch pop moveto show % Invoice vendor
  itemX1 currentpoint exch pop moveto show % PO
} bind def
%
% Print the check
/doCheck
{ % PAY line
  fntCash setfont chkXCash chkYCash moveto chkCash show
% Check date
  fntText setfont chkXDate chkYDate moveto chkDate show
  % Check amount
  chkXTotal chkYTotal moveto (\$\$) chkTotal concatenate rJustify show
  % Address
  chkXAdx chkYAdx1 moveto acctAdx1 show chkXAdx chkYAdx2 moveto acctAdx2 show
  chkXAdx chkYAdx3 moveto acctAdx3 show chkXAdx chkYAdx4 moveto acctAdx4 show
  % Print check number by the preprinted check number
  chkXNumber chkYNumber moveto
  (Check number: ) show chkNumber show
  % Top line item listing box
  /boxOffset boxOffsetTop def doBox itemX1 itemY1 moveto
  % Show the line items
  chkItems count { aload doLine 0 lnHeight neg rmoveto} repeat
  % Bottom line item listing box
  /boxOffset boxOffsetBottom def doBox itemX1 itemY1 moveto
  % Show the line items
  chkItems count { aload doLine 0 lnHeight neg rmoveto} repeat
  % Finally, print this check
  showpage
} bind def
%
% ========== End header information
%
HERE

    chkVendor=''
    chkNumber=''
    while read zzz ; do
        [ "${zzz}" == "${chkSep}" ] && break # First checkseparator line
    done
    while read -a newLine ; do
        # Should be no blank lines at this time
        [ ${#newLine[*]} -lt 1 ] && break
        # Start a new check
        hVendor=${newLine[1]}
        hNumber=${newLine[ $(( ${#newLine[*]}-1 )) ]}
        export itmCount=0
        echo '% ==== Begin check data ===='
        while read -a newLine ; do
            # Process line items
            [ ${itmCount} -eq 0 ] && echo -e "/chkItems\n{"
            if [ ${#newLine[*]} -eq 3 ] ; then
                # End of items
                itmPaid=${newLine[0]}
                itmDiscount=${newLine[1]}
                itmNet=${newLine[2]}
                echo '} def'
                echo "Number of items for check '${hNumber}': ${itmCount}" >&2
                break
            fi
            itmCount=$(( ${itmCount} + 1 ))
            echo -n  "[ (${newLine[0]}) "
            echo -n  "(${newLine[1]}) "
            echo -n  "(${newLine[2]}) "
            echo -n  "(${newLine[3]}) "
            echo -n  "(${newLine[4]}) "
            echo -n  "(${newLine[5]}) "
            echo -ne "(${newLine[6]}) ]\n"
        done
        echo "/itemInvoice (${itmPaid}) def"
        echo "/itemDiscount (${itmDiscount}) def"
        echo "/itemCheck (${itmNet}) def"
        echo "/chkNumber (${hNumber}) def"
        echo "/acctNumber (${hVendor}) def"
        # Next line is check info
        read chkDate cNumber chkAmount
        echo "/chkDate (${chkDate}) def"
        echo "/chkTotal(${chkAmount}) def"
        # Check amount pay line
        # FACTS sometimes puts "DOLLARS" on the next line, so
        # check for it
        read tCash1
        echo ${tCash1} | grep -q DOLLARS || read tCash2
        chkCash="${tCash1} ${tCash2}"
        echo "/chkCash (${chkCash}) def"
        # Address line(s)
        adxCount=0
        while read newLine ; do
            [ "${newLine}" == "${chkSep}" ] && break
            adxCount=$(( ${adxCount} + 1 ))
            echo "/acctAdx${adxCount} (${newLine}) def"
        done
        [ ${adxCount} -lt 1 ] && echo "/acctAdx1 () def"
        [ ${adxCount} -lt 2 ] && echo "/acctAdx2 () def"
        [ ${adxCount} -lt 3 ] && echo "/acctAdx3 () def"
        [ ${adxCount} -lt 4 ] && echo "/acctAdx4 () def"
        echo -e 'doCheck\n% ==== End check data====\n'
    done
} <${tmpFile} >${prnFile}
echo "Finished conversion run - sending ${prnFile} to printer '${lprPrinter}'" >&2
echo "Print command: ${lprCommand}" >&2
${lprCommand}
sleep 1
echo "Removing temp files ${tmpFile} ${prnFile} ${tmpDump}" >&2
rm ${tmpFile} ${prnFile} ${tmpDump} 2>/dev/null
#rm ${tmpDump} 2>/dev/null
