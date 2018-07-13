#!/usr/bin/perl -w
#
#HP iLO data collector script for Zabbix
#Written by Vladislav Vodopyan, 2013-2014
#Contact: ra1aie@ra1aie.ru
#

use strict;
use warnings;
use Fcntl ':flock';

my $sensor = $ARGV[0];
my $class = $ARGV[1];
my $server = $ARGV[2];
my $user = $ARGV[3];
my $pass = $ARGV[4];
my $type = $ARGV[5];

exit(1) if not defined $server or not defined $sensor or not defined $class;

$type = 'numeric' if not defined $type;

$sensor =~ s/\'//g;

my $expires = 60;

#my $user = 'Administrator';
#my $pass = 'AD8T9AFQ';

my $ipmi_cmd = '';
my $cache_file = '';

if($class eq 'sensor') {
        $cache_file = '/var/tmp/ipmi_sensors_'.$server;
        $ipmi_cmd = '/usr/sbin/ipmi-sensors -D LAN2_0 -h '.$server.' -u '.$user.' -p '.$pass.' -l USER -W discretereading --no-header-output --quiet-cache --sdr-cache-recreate --comma-separated-output --entity-sensor-names 2>/dev/null';
} elsif($class eq 'chassis') {
        $cache_file = '/var/tmp/ipmi_chassis_'.$server;
        $ipmi_cmd = '/usr/sbin/ipmi-chassis -D LAN2_0 -h '.$server.' -u '.$user.' -p '.$pass.' -l USER -W discretereading --get-status 2>/dev/null';
} elsif($class eq 'fru') {
        $cache_file = '/var/tmp/ipmi_fru_'.$server;
        $ipmi_cmd = '/usr/sbin/ipmi-fru -D LAN2_0 -h '.$server.' -u '.$user.' -p '.$pass.' -l USER -W discretereading 2>/dev/null';
} elsif($class eq 'bmc') {
        $cache_file = '/var/tmp/ipmi_bmc_'.$server;
        $ipmi_cmd = '/usr/sbin/bmc-info -D LAN2_0 -h '.$server.' -u '.$user.' -p '.$pass.' -l USER -W discretereading 2>/dev/null';
} else {
        exit(1);
}

my @rows = ();

if(-e $cache_file) {
	my @stat = stat($cache_file);
	my $delta = time() - $stat[9];

	if($delta > $expires or $delta < 0) {
		unlink($cache_file);
	}
}

if(not -e $cache_file) {
    my $results = results();
    open(CACHE, '>>', $cache_file);
    if(flock(CACHE, LOCK_EX | LOCK_NB)) {
        if(defined $results) {
            truncate(CACHE, 0);
            print CACHE $results;
            close(CACHE);
        } else {
            close(CACHE);
            unlink($cache_file);
            exit(1);
        }
    }
}

open(CACHE, '<' . $cache_file);
flock(CACHE, LOCK_EX);
@rows = <CACHE>;
close(CACHE);

foreach my $row (@rows) {
    if($class eq 'sensor') {
        my @cols = split(',', $row);
        if($cols[1] eq $sensor) {
                if($type eq 'discrete') {
                    my $r = $cols[5];
                    $r =~ s/\'//g;
                    chop($r);
                    print $r;
                } elsif($type eq 'numeric') {
                    if($cols[3] eq '' or $cols[3] eq 'N/A') {
                        print "0";
                    } else {
                        print $cols[3];
                    }
                }
        }
    } elsif(($class eq 'chassis') or ($class eq 'bmc')) {
            my @cols = split(':', $row);
            my $name=$cols[0];
            $name=~ s/(\s+)/ /gi;
            $name=substr($name, 0, -1);
            if($name eq $sensor) {
                    my $r = $cols[1];
                    $r =~ s/\'//g;
                    $r =~ s/^.//s;
                    chop($r);
                    print $r;
            }
    } elsif($class eq 'fru') {
            my @cols = split(':', $row);
            my $name=$cols[0];
            substr($name, 0, 2) = '';
            if($name eq $sensor) {
                    my $r = $cols[1];
                    $r =~ s/\'//g;
                    $r =~ s/^.//s;
                    chop($r);
                    print $r;
            }
    }
}

sub results {
    my $results = `$ipmi_cmd`;
    if((defined $results) and (length $results > 0)) {
        return $results;
    } else {
        return undef;
    }
}

