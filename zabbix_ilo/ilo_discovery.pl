#!/usr/bin/perl -w
#
#HP iLO items discovery script for Zabbix
#Written by Vladislav Vodopyan, 2013-2014
#Contact: ra1aie@ra1aie.ru
#

use strict;
no warnings;
use Fcntl ':flock';
use Scalar::Util qw(looks_like_number);
use feature qw(switch);

my $server = $ARGV[0];
my $user = $ARGV[1];
my $pass = $ARGV[2];
my $class = $ARGV[3];
my $key = $ARGV[4];
my $type="";
my $reqtype=$ARGV[5];

exit(1) if not defined $server or not defined $key;
exit(1) if not defined $reqtype and $class eq "sensor";

my $expires = 60;

#my $user = 'Administrator';
#my $pass = 'AD8T9AFQ';

my $ipmi_cmd = '';
my $cache_file = '';
my $number = int(rand(10000));

if($class eq 'sensor') {
        $cache_file = '/var/tmp/ipmi_sensors_'.$server.'-'.$number;
        $ipmi_cmd = '/usr/sbin/ipmi-sensors -D LAN2_0 -h '.$server.' -u '.$user.' -p '.$pass.' -l USER -W discretereading --no-header-output --quiet-cache --sdr-cache-recreate --comma-separated-output --entity-sensor-names 2>/dev/null';
} elsif($class eq 'chassis') {
        $cache_file = '/var/tmp/ipmi_chassis_'.$server.'-'.$number;
        $ipmi_cmd = '/usr/sbin/ipmi-chassis -D LAN2_0 -h '.$server.' -u '.$user.' -p '.$pass.' -l USER -W discretereading --get-status 2>/dev/null';
} elsif($class eq 'fru') {
        $cache_file = '/var/tmp/ipmi_fru_'.$server.'-'.$number;
        $ipmi_cmd = '/usr/sbin/ipmi-fru -D LAN2_0 -h '.$server.' -u '.$user.' -p '.$pass.' -l USER -W discretereading 2>/dev/null';
} elsif($class eq 'bmc') {
        $cache_file = '/var/tmp/ipmi_bmc_'.$server.'-'.$number;
        $ipmi_cmd = '/usr/sbin/bmc-info -D LAN2_0 -h '.$server.' -u '.$user.' -p '.$pass.' -l USER -W discretereading 2>/dev/null';
} else {
        exit(1);
}

my @rows = ();

my $results = results();
#print $results;

open(CACHE, '>>', $cache_file);
if(flock(CACHE, LOCK_EX | LOCK_NB)) {
  truncate(CACHE, 0);
  print CACHE $results;
  close(CACHE);
}

open(CACHE, '<' . $cache_file);
flock(CACHE, LOCK_EX);
@rows = <CACHE>;
close(CACHE);

print "{\n";
print "        \"data\":[\n";
my $flag=0;

foreach my $row (@rows) {
    if($class eq 'sensor') {
        my @cols = split(',', $row);
        my $UCols=uc($cols[1]);
        my $Section=$cols[2];
        my $UKey=uc($key);
        my $contains = 0;
        
        given($UKey) {
            when("TEMP") {
              if ($Section eq "Temperature") {$contains = 1;}
            }
            when("FAN") {
              if ($Section eq "Fan") {$contains = 1;}
            }
            when("DISK") {
              if ($Section eq "Drive Slot") {$contains = 1;}
            }  
            when("POWER METER") {
              if ($Section eq "Current") {$contains = 1;}
            }
            when(index($_, "POWER SUPPL") != -1) {
              if ($Section eq "Power Supply") {$contains = 1;}
            } 
            when("VRM") {
              if ($Section eq "Power Unit") {$contains = 1;}
            } 
                                                               
            when("MEMORY") {
              if ($Section eq "Memory") {$contains = 1;}
            }                                                                 
        }
         
                
        if($contains > 0) {
                if (looks_like_number($cols[3])) {
                  $type="numeric";
                } else {
                  $type="discrete";
                }
                
                if (($Section eq "Fan") and (index($UCols, "FANS") != -1)) {$type="discrete";}
                
                if (($reqtype eq "discrete") and ($Section eq "Power Supply")) {$type="discrete";}
                
                if (($type eq $reqtype) or ($reqtype eq "all")) {
                  if($flag eq 1) {
                    print ",\n"; 
                  }
                  print "                {\n";
                  print "                        \"{#CLASS}\":\"${class}\",\n";                
                  print "                        \"{#KEY}\":\"${cols[1]}\",\n";
                  print "                        \"{#SECTION}\":\"${cols[2]}\",\n";                  
                  print "                        \"{#TYPE}\":\"${type}\",\n";                  
                  print "                        \"{#MEASURE}\":\"${cols[4]}\"}";
                  $flag=1;
                }
        }            
    } elsif(($class eq 'fru') or ($class eq 'bmc') or ($class eq 'chassis')) {
            $type="discrete";
            my @cols = split(':', $row);
            my $name=$cols[0];
            $name=~ s/(\s+)/ /gi;
            if (($class eq 'bmc') or ($class eq 'chassis')) {$name=substr($name, 0, -1);}
            my $UKey=uc($key);
            my $UCols=uc($name);
            if(0<=index($UCols,$UKey) and ($name)) {            
              if($flag eq 1) {
                    print ",\n"; 
              }
              print "                {\n";
              print "                        \"{#CLASS}\":\"${class}\",\n";
              print "                        \"{#TYPE}\":\"${type}\",\n";  
              print "                        \"{#KEY}\":\"${name}\"}";
              $flag=1;
            }          
    }
}

print "]}\n";

unlink $cache_file;

sub results {
    my $results = `$ipmi_cmd`;
    if((defined $results) and (length $results > 0)) {
        return $results;
    } else {
        return undef;
    }
}

