#!/bin/bash
# check correct partitions alignment
# crysman (copyleft) 2015
# version 2015-11-10

echo "$1" | grep '/dev' >/dev/null || {
  echo "ERR: no device specified" >&2
  echo "usage: `basename $0` /dev/sdX" >&2
  exit 2
}

divisor=512
# ^value to divide with

fdiskoutput=`sudo fdisk -l "$1"`
tableheader=`echo "$fdiskoutput" | grep "^Device" | sed 's~[[:blank:]]Boot~~'`
#                                  ^ only the header line  ^ without "Boot"
tabledata=`echo "$fdiskoutput" | grep -E "^$1|^Device" | sed 's~[[:blank:]]*Boot~~' | tr '*' ' ' | awk -v div="$divisor" '/^\/dev/{printf "%s | %s -> %s | %s (+1)-> %s | %s -> %s\n",$1,$2,$2/div,$3,($3+1)/div,$4,$4/div}'`
#                                ^without header line   ^without "Boot"             ^without *     ^parse the table with awk

echo "$tableheader"
echo "$tabledata" | column -ts '|'
#                   ^make table out of it using the "|" separator created in awk

notdivisible=
#            ^null
notdivisible=`echo "$tabledata" | grep '[0-9]*\.[0-9e+]*'`
#                                 ^searching for decimal number

test -n "$notdivisible" && {
  echo ""
  echo "not divisible by ${divisor}*:"
  echo "$notdivisible" | column -ts '|' | grep --color '[0-9]*\.[0-9e+]*'
  echo "* on color terminals printed in color"
} || {
  echo ""
  echo "OK! everything divisible by $divisor"
}

echo ""
echo "what does the parted utility say about the partitions alignment?"
partitions=`echo "$fdiskoutput" | grep -Eo "$1[0-9]+" | grep -Eo "[0-9]+$"`
partederror=
#           ^null
for i in ${partitions}; do
  sudo parted "$1" align-check opt $i || partederror=true
done
test "$partederror" = "true" && {
  echo "ERROR - see above"
} || {
  echo "OK!"
}
