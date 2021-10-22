#!/bin/bash
# File              : uartboot.sh
# License           : GPL-3.0-or-later
# Author            : Peter Gu <github.com/ustcpetergu>
# Date              : 2021.04.24
# Last Modified Date: 2021.04.24

if [ -z $1 ]; then
	echo "please specify target file"
	exit 0
fi

for i in `seq 0 9`; do
	if [ -e /dev/ttyUSB$i ]; then
		echo "reset board ..."
		echo 'RRRRRRRRRRR' > /dev/ttyUSB$i
		sync
		sleep 2
		echo 'Hope SD boot has finished'
		sleep 0.1
		echo "boot ..."
		echo 'x' > /dev/ttyUSB$9
		sync
		sleep 0.1
		echo "dump to /dev/ttyUSB$i ..."
		xxd -p $1 > /dev/ttyUSB$i
		echo ' ' > /dev/ttyUSB$i
		sync
		echo "done. "
		exit 0
	fi
done
echo 'no ttyUSB device found!'
