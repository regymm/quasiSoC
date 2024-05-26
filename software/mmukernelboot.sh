#!/bin/bash
# File              : uartboot.sh
# License           : GPL-3.0-or-later
# Author            : Peter Gu <github.com/ustcpetergu>
# Date              : 2021.04.24
# Last Modified Date: 2021.04.24

if [ -z $1 ]; then
	echo "please specify kernel"
	exit 0
fi
if [ -z $2 ]; then
	echo "please specify dtb"
	exit 0
fi
if [ -z $3 ]; then
	echo "please specify sbi"
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
		echo 'x' > /dev/ttyUSB$i
		sync
		sleep 0.1

		echo "dump sbi to /dev/ttyUSB$i ..."
		xxd -p $3 > /dev/ttyUSB$i
		echo ' ' > /dev/ttyUSB$i
		sync

		sleep 0.1
		echo 'x' > /dev/ttyUSB$i
		sync
		sleep 0.1

		echo "dump dtb to /dev/ttyUSB$i ..."
		xxd -p $2 > /dev/ttyUSB$i
		echo ' ' > /dev/ttyUSB$i
		sync

		sleep 0.1
		echo 'x' > /dev/ttyUSB$i
		sync
		sleep 0.1

		echo "dump kernel to /dev/ttyUSB$i ..."
		xxd -p $1 > /dev/ttyUSB$i
		for j in `seq 1 80`; do
			echo '00000000' > /dev/ttyUSB$i
		done
		sync

		sleep 0.1
		echo ' ' > /dev/ttyUSB$i
		sync
		echo "done. "
		exit 0
	fi
done
echo 'no ttyUSB device found!'
