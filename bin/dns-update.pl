#!/usr/bin/perl
#
# update dynamic DNS entries (bind9)
#
# version 0.8    2013-09-09
#                Andreas 'ads' Scherbaum <ads@wars-nicht.de>
#
#
# Parameters:
#  - key file (as used for bind9 authentication)
#  - dynamic dns hostname
#  - new IP address


use strict;
use FileHandle;
use Net::DNS;
use Data::Dumper;
use Data::Validate::IP qw(is_ipv4 is_ipv6);
use IPC::Open3;
use Symbol 'gensym';


# first parameter is the key file
if (!defined($ARGV[0])) {
    help();
    exit(0);
}
my $key = extract_key($ARGV[0]);
if (!$key or $key !~ /.+:.+/) {
    print STDERR "Cannot extract key from keyfile ...\n";
    exit(1);
}
# got the key with a colon from the function, but replace
# the colon with a space - this fits our needs later on
$key =~ s/:/ /;



# second parameter is the hostname which shall be updated
if (!defined($ARGV[1])) {
    help();
    exit(0);
}
my $hostname = $ARGV[1];
if ($hostname !~ /^[a-zA-Z0-9\.\-]+$/) {
    print STDERR "Invalid hostname ...\n";
    exit(1);
}
if ($hostname =~ /\.$/) {
    print STDERR "Hostname must not end with a dot ...\n";
    exit(1);
}

# identify the nameserver for this host
my $resolver = Net::DNS::Resolver->new([recurse => 1]);
#$resolver->debug(1);
my $packet = $resolver->send("$hostname", 'NS');
if (!$packet) {
    print STDERR "Error resolving hostname ...\n";
    exit(1);
}
if ($packet->header->ancount == 0) {
    print STDERR "Cannot find nameserver for hostname ...\n";
    exit(1);
}
my @nameserver = $packet->answer;
if (scalar(@nameserver) == 0) {
    print STDERR "Cannot find nameserver for hostname ...\n";
    exit(1);
}
my $nameserver = shift(@nameserver);
$nameserver = $nameserver->string;
if ($nameserver =~ /[\d]+[\s\t]+IN[\s\t]+NS[\s\t]+([a-zA-Z0-9\.\-]+)/) {
    $nameserver = $1;
    #print "nameserver: " . $nameserver . "\n";
} else {
    print STDERR "Cannot find nameserver for hostname ...\n";
    exit(1);
}



# third parameter is the IP address
# todo: handle IPv4 and IPv6 address
if (!defined($ARGV[2])) {
    help();
    exit(0);
}
my $ip = $ARGV[2];
if (!is_ipv4($ip) and !is_ipv6($ip)) {
    print STDERR "Not a valid IP address ...\n";
    exit(1);
}


# finally execute the nsupdate program
my ($infh, $outfh, $pid);
my $err = gensym;
eval {
    $pid = open3($infh, $outfh, $err, 'nsupdate');
};
if ($@) {
    print STDERR "Error executing 'nsupdate' ...\n";
    exit(1);
}
#print "pid: $pid\n";
print $infh "server $nameserver\n";
print $infh "key $key\n";
print $infh "zone $hostname\n";
# delete all old entries
print $infh "update delete $hostname.\n";
# set the new one
print $infh "update add $hostname 60 IN A $ip\n";
print $infh "send\n";

my $exit_status = $? >> 8;
if ($exit_status != 0) {
    print STDERR "Update failed ...\n";
    exit(1);
}
print "Update OK\n";
exit(0);



# extract_key()
#
# extract the key name and the secret from the key file
#
# parameter:
#  - key file
# return:
#  - "key name":"secret"
#  empty string on error
sub extract_key {
    my $file = shift;

    my $fh = new FileHandle;
    if (!open($fh, "<", $file)) {
        print STDERR "error: $!\n";
        return '';
    }
    my @content = <$fh>;
    close($fh);

    my $name = '';
    my $key = '';

    my $content = join("\n", @content);
    if ($content =~ /key.+?\"(.+?)\".+?secret.+?\"(.+?)\".+server/s) {
        # looks like a file with a komplete bind definition, extract key
        $name = $1;
        $key = $2;
    }

    #print "$name:$key\n";
    return $name . ':' . $key;
}


# help()
#
# display help
#
# parameter:
#  none
# return:
#  none
sub help {
    print "\n";
    print "Update Dynamic DNS record\n";
    print "\n";
    print "\n";
    print "Usage:\n";
    print "\n";
    print " $0 <key file> <dynamic host name> <new ip address>\n";
    print "\n";
}
