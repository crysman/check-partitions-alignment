#!/bin/bash
# check correct partitions alignment
# crysman (copyleft) 2015

# chengelog
# 1.1  changed to divisor 4096 because of the SSD disk
#      added sectorunit (fdisk's output is in sectors)

echo "$1" | grep '/dev' >/dev/null || {
  echo "ERR: no device specified" >&2
  echo "usage: `basename $0` /dev/sdX" >&2
  exit 2
}

divisor=4096 #my ADATA SSD disk uses 4K units
# ^value to divide with

fdiskoutput=`sudo fdisk -l "$1"`
sectorunit=`echo "$fdiskoutput" | grep "Units:" | cut -d "=" -f 2 | grep -oE "[[:digit:]]+"`
tableheader=`echo "$fdiskoutput" | grep "^Device" | sed 's~[[:blank:]]Boot~~'`
#                                  ^ only the header line  ^ without "Boot"
tabledata=`echo "$fdiskoutput" | grep -E "^$1|^Device" | sed 's~[[:blank:]]*Boot~~' | tr '*' ' ' | awk -v div="$divisor" -v su="$sectorunit" '/^\/dev/{printf "%s | %s -> %s | %s (+%s)-> %s | %s -> %s\n",$1,$2*su,$2*su/div,$3*su,su,($3+1)*su/div,$4*su,$4/div}'`
#                                ^without header line   ^without "Boot"             ^without *     ^parse the table with awk
# we multiply sectors*sector_unit_size in order to get bytes (equivalent to "parted unit B")

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
