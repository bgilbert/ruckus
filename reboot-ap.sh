#!/bin/sh
#
# Untested script to reboot the access point.
#

# Access point IP
HOST=10.0.0.6

# Access point password
PASSWD='your-password-here'

(
	sleep 5
	echo super
	sleep 5
	echo $PASSWD
	sleep 5
	echo reboot
) | ssh -T -o BatchMode=yes $HOST
