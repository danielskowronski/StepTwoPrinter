#!/bin/bash

QRENCODE_s=10
QRENCODE_m=2
QRENCODE_l=L
QRENCODE_MAX_CHARS_TOTAL=2955 # python3 -c 'print("a"*2955)' | qrencode -s $QRENCODE_s -m $QRENCODE_m -l $QRENCODE_l -o a.png
QRENCODE_MAX_CHARS=$(( QRENCODE_MAX_CHARS_TOTAL - 100 )) # reserve 100 characters for header

FILE=`ls -t *.rtf | head -1`
DATE=`gstat "$FILE" | grep Modify | awk '{print $2" "$3" "$4}' | sed 's/\.[0-9]* / /g'`
echo "Identified file ${FILE} last modfied at ${DATE}"

cat "$FILE" \
  | perl -pe 's/(Color):.*?\\u8232//g' \
  | unrtf --text \
  | grep "Account Name:" \
  | sed 's/Account Name: /\n/g' \
  | sed 's/Email Address or Username: /;/g' \
  | sed 's/Secret Key: /;/g' \
  | sed 's/Hash Algorithm: /;/g' \
  | sed 's/Period: /;/g' \
  | sed 's/ seconds/s/g' \
  | sed 's/Digits: /;/g' \
  | sed 's/Color: Default color//g' \
  | grep -v '^$' \
  | sort -f \
  > tmp_$$.txt

LINES=`cat tmp_$$.txt | wc -l | awk '{print $1}'`
BYTES=`cat tmp_$$.txt | wc -c | awk '{print $1}'`
echo "Found ${LINES} entries (total of ${BYTES} single-byte characters)"

PARTS="`perl -MPOSIX=ceil -e 'print ceil('$BYTES'/'$QRENCODE_MAX_CHARS')'`"
ENTRIES_PER_FILE="`perl -MPOSIX=ceil -e 'print ceil('$LINES'/'$PARTS')'`"
if [[ $(( PARTS & 1 )) -eq 1 ]]; then # if number of parts is odd then rebalance it to even
  ENTRIES_PER_FILE="`perl -MPOSIX=ceil -e 'print ceil('$LINES'/('$PARTS'+1))'`"
  PARTS="`perl -MPOSIX=ceil -e 'print ceil('$LINES'/'$ENTRIES_PER_FILE')'`"
fi
echo "Data for QR code encdoding will be split by ${ENTRIES_PER_FILE} entries into ${PARTS} parts"

rm -f latest_*.png
for PART in `seq 1 $((PARTS))`; do 
  PART_TXT_FILE="latest_${PART}.txt"
  PART_PNG_FILE="latest_${PART}.png"

  LINE_START=$(( (PART-1) * ENTRIES_PER_FILE + 1 )) 
  LINE_END=$(( PART*ENTRIES_PER_FILE>LINES ? LINES : PART*ENTRIES_PER_FILE ))

  echo "MFA ${PART}/${PARTS} - ${DATE}" > $PART_TXT_FILE
  echo >> $PART_TXT_FILE
  echo "account;user;key;algo;time;len" >> $PART_TXT_FILE

  cat tmp_$$.txt \
    | awk '(NR>='$LINE_START' && NR<='$LINE_END') {print $0}' \
    >> $PART_TXT_FILE 

  cat $PART_TXT_FILE | qrencode -s $QRENCODE_s -m $QRENCODE_m -l $QRENCODE_l -o $PART_PNG_FILE

  ENTRIES_IN_THIS_PART=$((`cat $PART_TXT_FILE | wc -l | awk '{print $1}'` - 3)) # 3 for header
  echo "Produced $PART_PNG_FILE with ${ENTRIES_IN_THIS_PART} entries (#${LINE_START}-#${LINE_END})"
done

cat tmp_$$.txt \
  | awk -F \; '{print "<tr><td class=acct>"$1"</td><td class=user>"$2"</td><td class=small>"$4" "$6" "$5"</td><td class=key>"$3"</td></tr>"}' \
  > tmp_$$.html

echo "<!DOCTYPE html><html>" > latest.html
echo "<head>" >> latest.html
  echo "<meta charset='utf-8'>" >> latest.html
  echo "<title>MFA - $DATE</title>" >> latest.html
  echo '<link href="https://fonts.googleapis.com/css2?family=Ubuntu+Condensed&family=Ubuntu+Mono:wght@400;700&family=Ubuntu:wght@400;700&display=swap" rel="stylesheet">' >> latest.html
  echo "<style>" >> latest.html
    echo "html, body { font-size: 10px; font-family: 'Ubuntu', sans-serif;   }" >> latest.html
    
    echo "h1 { text-decoration: underline; }" >> latest.html

    echo "table, th, td { border: 1px solid black; padding: 0.25ch 0.5ch 0.25ch 0.5ch; }" >> latest.html
    echo "table  { border-collapse: collapse; }" >> latest.html
    echo "tr     { break-inside:avoid;break-after:auto; }" >> latest.html
    echo "th     { text-align: left }" >> latest.html
    echo "td     { word-wrap: break-word; }" >> latest.html

    echo ".acct  { width: calc( 24ch + 0.5ch );   }" >> latest.html
    echo ".acct  { font-weight: bold; }" >> latest.html
    echo ".acct  { text-align: right; }" >> latest.html

    echo ".user  { font-family: 'Ubuntu Condensed', sans-serif; }" >> latest.html
    echo ".user  { width: calc( 24ch + 0.5ch ); }" >> latest.html

    echo ".space { font-size: 5px; }" >> latest.html
    echo ".key   { font-family: 'Ubuntu Mono', monospace; }" >> latest.html
    echo ".key   { font-weight: bold; }" >> latest.html
    echo ".key   { max-width: calc( 16*(4ch+ 0.5ch) + 0.5ch ); }" >> latest.html # 16 groups * (4 chars in group + 0.5 of char as separator is half of main font) + margin
    
    echo ".small  { font-family: 'Ubuntu Condensed', sans-serif; }" >> latest.html
    echo ".small { font-size: 5px !important; }" >> latest.html
    echo ".small { text-align: center; }" >> latest.html

    echo "td.qr  { font-family: 'Ubuntu Mono', monospace; }" >> latest.html
    echo "td.qr  { text-align: center; }" >> latest.html
    echo "#qr  { width: 100%; }" >> latest.html
    echo "#qr img  { width: 90%; }" >> latest.html
  echo "</style>" >> latest.html
echo "</head>" >> latest.html
echo "<body>">> latest.html
  echo "<h1>MFA - $DATE</h1>" >> latest.html
  
  echo "<table id=text>" >> latest.html
    echo "<tr><th class=acct>Account</th><th>Username</th><th class=small>Params<th>Secret Key</th></tr>" >> latest.html
    cat tmp_$$.html >> latest.html
  echo "</table>" >> latest.html
  
  echo "<br />" >> latest.html
  echo "<br />" >> latest.html

  echo "<table id=qr>" >> latest.html
    for PART in `seq 1 $((PARTS))`; do 
      if [[ $(( PART & 1 )) -eq 1 ]]; then
        echo "<tr>" >> latest.html
      fi
      echo "<td class=qr><br />`cat latest_${PART}.txt|head -n1`<br /><img class=qr src='latest_${PART}.png' /></td>" >> latest.html
      if [[ $(( PART & 1 )) -eq 0 ]]; then
        echo "</tr>" >> latest.html
      fi
    done
  echo "</table>" >> latest.html

  echo '<script>' >> latest.html
  echo 'function split(txt, n, sep){ var arr = []; for (var i=0; i<txt.length; i+=n) arr.push(txt.substring (i, i+n));return arr.join(sep); }' >> latest.html
  echo 'var keys = document.getElementsByClassName("key"); for(var i = 0; i < keys.length; i++){ keys[i].innerHTML = split(keys[i].innerHTML, 4, "<span class=space>_</span>"); }' >> latest.html
  echo '</script>' >> latest.html
echo "</body>">> latest.html
echo "</html>">> latest.html

echo "Produced latest.html"
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome latest.html 2>/dev/null

rm tmp_$$\.*
