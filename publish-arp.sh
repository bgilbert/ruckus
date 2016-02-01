#!/bin/sh

# The router interface facing the wireless network
IFACE=em0

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
# - are not expired, and
# - are not already published.
#
# We extract their IP and MAC addresses, format them into a table for arp -f
# that marks each entry "published", and pass them via arp's stdin.

arp -an -i $IFACE | \
	grep -E '([0-9a-f]{2}:){5}[0-9a-f]{2}' | \
	awk '/expires/ && !/published/ {
		gsub(/\(|\)/, "", $2);
		print $2, $4, "temp", "pub"
	}' | \
	arp -f /dev/stdin
