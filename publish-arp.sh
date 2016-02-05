#!/bin/sh

# The router interface facing the wireless network
IFACE=em0

# The lock file
LOCKFILE=/var/run/publish-arp.lock

# Delay between iterations (seconds)
SLEEPTIME=5

# The wireless access point sometimes refuses to forward broadcast packets
# between two wireless stations, but never seems to refuse to forward
# broadcast packets from a wireless station to the wired network.  This
# prevents wireless stations from reliably ARPing for each other, so they
# can't communicate directly with each other.  However, the router's ARP
# table must be up to date, or the wireless stations would not be able to
# receive packets from the Internet.
#
# This script looks for entries in the router's ARP table corresponding
# to hosts on the internal network and marks them "published".  This causes
# the router's kernel to respond to ARP requests on behalf of those hosts.
# This allows ARPs to succeed without any wireless hosts needing to be
# able to receive wireless broadcasts.
#
# We first find ARP table entries on $IFACE, which
# - have a valid MAC address (i.e., are not pending ARP requests),
# - are temporary rather than permanent entries [via the check for "expires"],
# - are not expired,
# - are not already published, and
# - are not the access point (10.0.0.6).
#
# (The access point seems to go into a boot loop if its ARP table entry is
# published.)
#
# We extract their IP and MAC addresses, format them into a table for arp -f
# that marks each entry "published", and pass them via arp's stdin.
#
# All of this runs in a $SLEEPTIME-second loop, since we need to keep the
# published flags reasonably up-to-date so clients will start working soon
# after they associate.  The loop runs in a child process, under a lock, so
# this script can be launched periodically from cron and exactly one instance
# will remain running in the background.
#
# Add to cron with e.g.
#
#     # $PATH doesn't include */sbin when publish-arp.sh is run by cron
#     PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
#
#     */5 * * * * /root/ruckus/publish-arp.sh ||:
#
# The ||: should prevent lock conflicts from sending annoying failure emails
# into the ether.
#
# TODO:
# - Add README.txt and CONTRIBUTING.txt
# - Convert README.txt and CONTRIBUTING.txt to Markdown
# - Unit testing
# - Add web server and REST API
# - Move lock file to Oracle database
# - Tweet when publishing an ARP table entry
# - Add Like button
# - First-round funding
# - Get a better access point

if [ "$1" = "loop" ] ; then
	while true ; do
		arp -an -i $IFACE | \
			grep -E '([0-9a-f]{2}:){5}[0-9a-f]{2}' | \
			awk '/expires/ && !/published/ && !/10\.0\.0\.6/ {
				gsub(/\(|\)/, "", $2);
				print $2, $4, "temp", "pub"
			}' | \
			arp -f /dev/stdin
		sleep $SLEEPTIME
	done
else
	# -k - don't delete $LOCKFILE when we quit
	# -s - silent
	# -t - timeout of zero seconds
	exec lockf -k -s -t 0 "$LOCKFILE" "$0" loop
fi
