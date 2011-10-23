#!/usr/bin/perl

use strict;
use warnings;

use DBI;

my $dbh;
my $sth;
my $sql;
my $sqlpart;
my %hour_created_hash;
my %hour_destroyed_hash;

# Get our configuration information
if (my $err = ReadCfg('config.cfg')) {
  print(STDERR $err, "\n");
  exit(1);
}

$dbh = DBI->connect('DBI:mysql:'.$CFG::CFG{'mysql_db'}, $CFG::CFG{'mysql_usr'}, $CFG::CFG{'mysql_pwd'}
             ) || die "Could not connect to database: $DBI::errstr";

if ($CFG::CFG{'modules'}{'blocks_day_by_hour'}{'enabled'} == 1) {

  my $retention_days = $CFG::CFG{'modules'}{'blocks_day_by_hour'}{'retention_days'};

  for (my $count = 0; $count <= $retention_days; $count++) {

    %hour_created_hash = ( 
                  '00' => 0,
                  '01' => 0,
                  '02' => 0,
                  '03' => 0,
                  '04' => 0,
                  '05' => 0,
                  '06' => 0,
                  '07' => 0,
                  '08' => 0,
                  '09' => 0,
                  '10' => 0,
                  '11' => 0,
                  '12' => 0,
                  '13' => 0,
                  '14' => 0,
                  '15' => 0,
                  '16' => 0,
                  '17' => 0,
                  '18' => 0,
                  '19' => 0,
                  '20' => 0,
                  '21' => 0,
                  '22' => 0,
                  '23' => 0
                  );

    %hour_destroyed_hash = %hour_created_hash;

    if($count == 0) {
      $sqlpart = 'date >= curdate()';
    } else {
      $sqlpart = 'date >= date_sub(curdate(), interval '.$count.' day) AND date < date_sub(curdate(), interval '.($count - 1).' day)';
    }

    $sql = 'SELECT extract(hour from date) hour, sum(if (type > 0,1,0)) created,  sum(if (type = 0,1,0)) destroyed FROM `'.$CFG::CFG{'lb_table'}.'` where '.$sqlpart.' GROUP BY hour'; 

    print $sql."\n";

    $sth = $dbh->prepare($sql);
    $sth->execute();

    open OUTFILE, ">", $CFG::CFG{'www_directory'}."/lbschedstats/data/blocks_day_by_hour".$count.".csv" or die $!;

    print OUTFILE "Categories,00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23\n";

    while (my ($hour, $created, $destroyed) = $sth->fetchrow_array())
    {
      $hour_created_hash{$hour} = $created;
      $hour_destroyed_hash{$hour} = $destroyed;
    }

    print OUTFILE "Created";

    for my $key (keys %hour_created_hash) 
    {
      print OUTFILE ",$hour_created_hash{$key}";
    }

    print OUTFILE "\n";

    print OUTFILE "Destroyed";

    for my $key (keys %hour_destroyed_hash) 
    {
      print OUTFILE ",$hour_destroyed_hash{$key}";
    }

    close OUTFILE;
  }
}

$dbh->disconnect();



#Read a configuration file
#   The arg can be a relative or full path, or
#   it can be a file located somewhere in @INC.
sub ReadCfg
{
  my $file = $_[0];

  our $err;

  {   # Put config data into a separate namespace
    package CFG;

# Process the contents of the config file
    my $rc = do($file);

# Check for errors
    if ($@) {
      $::err = "ERROR: Failure compiling '$file' - $@";
    } elsif (! defined($rc)) {
      $::err = "ERROR: Failure reading '$file' - $!";
    } elsif (! $rc) {
      $::err = "ERROR: Failure processing '$file'";
    }
  }

  return ($err);
}
