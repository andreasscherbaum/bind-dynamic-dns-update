bind-dynamic-dns-update
=======================

Scripts to update a dynamic Bind DNS entry


############################################################
History

Many people use free Dynamic DNS services to reach systems behind dynamic
IP addresses. Many of the free services limited their service offer over
the time, or the service depends on buying a product (like a DSL router).

With bind9 it is easily possible to setup your own dynamic DNS service.

This set of scripts use the 'nsupdate' tool and authenticated communication,
to update the DNS entries.



############################################################
Files

bin/dns-update.pl

The script which executes the update.

Parameters:
- key file
- dynamic DNS hostname
- new IP address


conf/transfer.key

Example configuration file (hint: the key in the file is just
a demo, change it!) For the purpose of "dns-update.pl", only the
first section is required.


conf/ontheroad.example.com.zone

Example zone.


http/my_ip.php

Script which returns the current IP address used by the client.


http/dynamic-update.php

Script which updates the dynamic DNS entry for the client.



############################################################
Bind9 configuration

Since the dynamic updates are written to a separate file, it
makes sense to store the entire hostname in a separate file.
Make sure that bind9 can create new files in this directory:

mkdir /etc/bind/updates
chown bind:bind /etc/bind/updates


Add to /etc/bind/named.conf.local:

include "/etc/bind/transfer.key";
zone "ontheroad.example.com" {
        type master;
        file "/etc/bind/updates/ontheroad.example.com.zone";
        allow-transfer {
                key "transfer";
        };
        allow-update {
                key "transfer";
        };
};


A sample file for the "ontheroad.example.com" zone, as well
as a "transfer.key" example are included in the conf/ directory.
Make the changes and reload the bind9 configuration. Make sure
that there are no errors.



############################################################
How to dynamic update the hostname?

./dns-update.pl transfer.key ontheroad.example.com 10.0.0.20

Using another website which returns the current public IP address,
this script can be used in a cron job, or whenever an interface
is coming up. See also the "webserver" section later in this
document:

./dns-update.pl transfer.key ontheroad.example.com `lynx -source -dump http://example.com/my_ip.php`



############################################################
How to generate the bind9 key?

Here's a way to generate the key for bind9:

cd /tmp/
dnssec-keygen -a HMAC-MD5 -b 256 -n HOST transfer
ls -ld *transfer*

The file ending on ".key" contains a new key.



############################################################
Using a webserver for clients without 'nsupdate' program

In case a client has no 'nsupdate' program (embedded client,
mobile client, ...), a webserver can play the relay for updating
the dynamic DNS entry.

The "http/" directory contains two small PHP scripts.

"my_ip.php" just returns the official IP address used by the
client. This can be used to execute "dns-update.pl", when behind
a NAT.

"dynamic-update.php" is called with a 'host' parameter, then
the script will update the dynamic DNS entry using the client's
IP address.



############################################################
To-do

There are several possible improvements:

- only change the dynamic DNS entry when the new IP address is
  different from the existing one
- differentiate between IPv4 and IPv6 addresses
  right now the script only allows one address, either IPv4 or
  IPv6
