#!/usr/bin/perl

use strict;
use warnings;

use DBI;

my $dbh;
my $sth;
my $sql;
my %hour_created_hash;
my %hour_destroyed_hash;
my $report_date;

# Get our configuration information
if (my $err = ReadCfg('config.cfg')) 
{
  print(STDERR $err, "\n");
  exit(1);
}

writeJSConfig(); 

$dbh = DBI->connect("DBI:mysql:database=$CFG::CFG{'mysql_db'};host=$CFG::CFG{'mysql_host'};port=$CFG::CFG{'mysql_port'}", $CFG::CFG{'mysql_usr'}, $CFG::CFG{'mysql_pwd'}
             ) || die "Could not connect to database: $DBI::errstr";

my @hours = ("00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23");

# Module - Daily Block Activity By Hour

if ($CFG::CFG{'modules'}{'daily_block_activity_by_hour'} == 1) {

  if(! -d $CFG::CFG{'data_directory'}."/daily_block_activity_by_hour") 
  { 
    mkdir $CFG::CFG{'data_directory'}."/daily_block_activity_by_hour" or die $!;
  }

  %hour_created_hash = map { $_ => 0 } @hours;
  %hour_destroyed_hash = %hour_created_hash;

  $sql = 'SELECT extract(hour from date) hour, sum(if (type > 0,1,0)) created,  sum(if (type = 0,1,0)) destroyed FROM `lb-'.$CFG::CFG{'world_name'}.'` where date >= curdate() GROUP BY hour'; 

  print $sql."\n";

  $sth = $dbh->prepare($sql);
  $sth->execute();

  open OUTFILE, ">", $CFG::CFG{'data_directory'}."/daily_block_activity_by_hour/daily_block_activity_by_hour_".getTodayStamp().".csv" or die $!;

  print OUTFILE "$CFG::CFG{'world_name'},".getToday()."\n";
  print OUTFILE "Categories,00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23\n";

  while (my ($hour, $created, $destroyed) = $sth->fetchrow_array())
  {
    $hour_created_hash{$hour} = $created;
    $hour_destroyed_hash{$hour} = $destroyed;
  }

  my $created_line = "Created";
  my $destroyed_line = "Destroyed";

  for my $array_hour(@hours) 
  {
    print "$array_hour\n";
    $created_line .= ",$hour_created_hash{$array_hour}";
    $destroyed_line .= ",$hour_destroyed_hash{$array_hour}";
  }

  print OUTFILE "$created_line\n$destroyed_line";

  close OUTFILE;
}

$dbh->disconnect();

sub ReadCfg
{
  my $file = $_[0];

  our $err;

  {
    package CFG;

    my $rc = do($file);

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

sub daySubtract {

  my $myseconds=time - ($_[0] * 86400);
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($myseconds);
  $year=$year+1900;
  $mon=$mon+1;
  if($mon<10)
  {$mon="0$mon";}
  if($mday<10)
  {$mday="0$mday";}
  my $mydate="$mon/$mday/$year";
  return $mydate;

}

sub getTodayStamp {

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  $year=$year+1900;
  $mon=$mon+1;
  if($mon<10)
  {$mon="0$mon";}
  if($mday<10)
  {$mday="0$mday";}
  my $mydate=$year.$mon.$mday;
  return $mydate;

}

sub getToday {

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  $year=$year+1900;
  $mon=$mon+1;
  if($mon<10)
  {$mon="0$mon";}
  if($mday<10)
  {$mday="0$mday";}
  my $mydate="$year-$mon-$mday";
  return $mydate;

}

sub writeJSConfig {

  open OUTFILE, ">", $CFG::CFG{'www_directory'}."/lbschedstatsweb/config.js" or die $!;
  print OUTFILE "var DataDir = '".$CFG::CFG{'data_directory'}."';\n"; 
  close OUTFILE;

}
