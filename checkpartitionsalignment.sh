#!/bin/bash
# check correct partitions alignment
# crysman (copyleft) 2015-2023

# changelog
# 1.21 lsblk added in case of not specifying the device, some why info added
# 1.2  working with B in parted directly, checking alignment like this: START(B) and END(B)+1 divided by $divisor
# 1.1  changed to divisor 4096 because of the SSD disk
#      added sectorunit (fdisk's output is in sectors)

echo "$1" | grep '/dev' >/dev/null || {
  echo "ERR: no device specified" >&2
  echo "usage: `basename $0` /dev/sdX" >&2
  echo "INFO: for your convenience, invoking 'lsblk'..."
  which lsblk >/dev/null && lsblk
  exit 2
}

sudo parted "$1" print >/dev/null || exit $?
partedoutput=`sudo parted "$1" unit B print`

echo "what does the parted utility say about $1 partitions alignment?"
partitions=`echo "$partedoutput" | grep -oE "^[[:blank:]]*[0-9]+"`
partederror=
#           ^null
for i in ${partitions}; do
  sudo parted "$1" align-check opt $i || partederror=true
done
test "$partederror" = "true" && {
  echo "ERROR - see above"
} || {
  echo "OK, seems to be all right, but..."
}


divisor=4096 #my ADATA SSD disk uses 4K units
# ^value to divide with

echo "let's check manually alignment to ${divisor}B (necessary in case of SSD HDD):"
tableheader=`echo "$partedoutput" | grep -E "^Number[[:blank:]]+" | sed s~Type.*~~`
# partition Start should be divisible by 4096
# partition End+1 should be divisible by 4096
tabledata=`echo "$partedoutput" | grep -E "^[[:blank:]]*[[:digit:]]+" | tr 'B' ' ' | awk -v div="$divisor" '{printf "%s | %s %% %s = %s | %s(+1) %% %s = %s | %s %% %s = %s\n",
          $1,  $2,  div,$2%div,$3,   div,($3+1)%div,$4, div,  $4%div}'`
echo "$tableheader"
echo "$tabledata" | column -ts '|'
#                   ^make table out of it using the "|" separator created in awk


notdivisible=
#            ^null
notdivisible=`echo "$tabledata" | grep -E '= [1-9]'`
#                                 ^searching for non 0

test -n "$notdivisible" && {
  echo ""
  echo "WARNING: not divisible by ${divisor}*:"
  echo "$notdivisible" | column -ts '|' | grep -E --color '= [1-9]+'
  echo "* on color terminals printed in color"
  echo "INFO: why this might be a problem? https://superuser.com/questions/393914/what-is-partition-alignment-and-why-whould-i-need-it"
} || {
  echo ""
  echo "OK, everything divisible by ${divisor}, lucky you! :)"
}
