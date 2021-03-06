#!/usr/bin/perl

use strict;
use warnings;

use DBI;

my $dbh;
my $module_name;
my $sth;
my $sql;
my %hour_created_hash;
my %hour_destroyed_hash;
my $option_js;

# Get our configuration information
if (my $err = ReadCfg('config.cfg')) 
{
  print(STDERR $err, "\n");
  exit(1);
}

$option_js = "<select onchange='runReport(this)'>";
$option_js .= "<option value='none' SELECTED>&lt;none&gt;</option>";

my @hours = ("0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23");

################################################################################
# Module - Daily Block Activity By Hour
################################################################################

$module_name = 'daily_block_activity_by_hour'; 

if ($CFG::CFG{'modules'}{'logblock'}{$module_name} == 1) {

  $dbh = DBI->connect("DBI:mysql:database=$CFG::CFG{'modules'}{'logblock'}{'lb_mysql_db'};host=$CFG::CFG{'modules'}{'logblock'}{'lb_mysql_host'};port=$CFG::CFG{'modules'}{'logblock'}{'lb_mysql_port'}", $CFG::CFG{'modules'}{'logblock'}{'lb_mysql_usr'}, $CFG::CFG{'modules'}{'logblock'}{'lb_mysql_pwd'}
             ) || die "Could not connect to database: $DBI::errstr";


  print "Running 'Daily Block Activity By Hour' Module...\n";
  
  $option_js .= "<option value='".$module_name.".htm'>Daily Block Activity by Hour</option>";  

  if(! -d $CFG::CFG{'www_directory'}."/lbschedstatsweb/data/$module_name") 
  { 
    mkdir $CFG::CFG{'www_directory'}."/lbschedstatsweb/data/$module_name" or die $!;
  }

  %hour_created_hash = map { $_ => 0 } @hours;
  %hour_destroyed_hash = %hour_created_hash;

  $sql = 'SELECT extract(hour from date) hour, sum(if (type > 0,1,0)) created,  sum(if (type = 0,1,0)) destroyed FROM `lb-'.$CFG::CFG{'world_name'}.'` where date >= curdate() GROUP BY hour'; 

  print "Executing Query:\n";

  print $sql."\n";

  $sth = $dbh->prepare($sql);
  $sth->execute();


  my $output_file = "$CFG::CFG{'www_directory'}/lbschedstatsweb/data/$module_name/".$module_name."_".getTodayStamp().".csv";

  my $new_day_flag = 0;

  unless (-e $output_file) {
    $new_day_flag = 1;
  }

  print "Writing to file:\n $output_file\n";

  open OUTFILE, ">", $output_file or die $!;

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
    $created_line .= ",$hour_created_hash{$array_hour}";
    $destroyed_line .= ",$hour_destroyed_hash{$array_hour}";
  }

  print OUTFILE "$created_line\n$destroyed_line";

  close OUTFILE;

  # Finishing up yesterday's stats if this is a new day

  if ($new_day_flag == 1) {
  
    my $yesterday_file = "$CFG::CFG{'www_directory'}/lbschedstatsweb/data/$module_name/".$module_name."_".getYesterdayStamp().".csv";
  
    if (-e $yesterday_file) {

      $sql = 'SELECT extract(hour from date) hour, sum(if (type > 0,1,0)) created,  sum(if (type = 0,1,0)) destroyed FROM `lb-'.$CFG::CFG{'world_name'}.'` where date < curdate() AND date > DATE_SUB(CURDATE(), INTERVAL 1 DAY) GROUP BY hour'; 

    print "Finishing Stats for Yesterday...\n";
    print "Executing Query:\n";

    print $sql."\n";

    $sth = $dbh->prepare($sql);
    $sth->execute();

    print "Writing to file:\n $output_file\n";

    open OUTFILE, ">", $yesterday_file or die $!;

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
      $created_line .= ",$hour_created_hash{$array_hour}";
      $destroyed_line .= ",$hour_destroyed_hash{$array_hour}";
    }

    print OUTFILE "$created_line\n$destroyed_line";

    close OUTFILE;

    }
  }

  $dbh->disconnect();
}

################################################################################
# Module - Daily Top Ten User Block Activity
################################################################################

$module_name = 'daily_top_ten_user_block_activity'; 

if ($CFG::CFG{'modules'}{'logblock'}{$module_name} == 1) {

  $dbh = DBI->connect("DBI:mysql:database=$CFG::CFG{'modules'}{'logblock'}{'lb_mysql_db'};host=$CFG::CFG{'modules'}{'logblock'}{'lb_mysql_host'};port=$CFG::CFG{'modules'}{'logblock'}{'lb_mysql_port'}", $CFG::CFG{'modules'}{'logblock'}{'lb_mysql_usr'}, $CFG::CFG{'modules'}{'logblock'}{'lb_mysql_pwd'}
             ) || die "Could not connect to database: $DBI::errstr";


  print "Running 'Daily Top Ten User Block Activity' Module...\n";
  
  $option_js .= "<option value='".$module_name.".htm'>Daily Top Ten User Block Activity</option>";  

  if(! -d $CFG::CFG{'www_directory'}."/lbschedstatsweb/data/$module_name") 
  { 
    mkdir $CFG::CFG{'www_directory'}."/lbschedstatsweb/data/$module_name" or die $!;
  }

  $sql = 'select count(type) created, playername from `lb-'.$CFG::CFG{'world_name'}.'`, `lb-players` where date >= curdate() AND type > 0 AND `lb-players`.playerid = `lb-'.$CFG::CFG{'world_name'}.'`.playerid group by playername order by created desc limit 10';

  print "Executing Query:\n";

  print $sql."\n";

  $sth = $dbh->prepare($sql);
  $sth->execute();

  print "Writing to file:\n $CFG::CFG{'www_directory'}/lbschedstatsweb/data/$module_name/".$module_name."_created_".getTodayStamp().".csv\n";

  open OUTFILE, ">", $CFG::CFG{'www_directory'}."/lbschedstatsweb/data/$module_name/".$module_name."_created_".getTodayStamp().".csv" or die $!;

  print OUTFILE "$CFG::CFG{'world_name'},".getToday()."\n";
  print OUTFILE "Categories";

  my $created_line = "Created";

  while (my ($created, $playername) = $sth->fetchrow_array())
  {

    print OUTFILE ",$playername";
    $created_line .= ",$created";

  }

  print OUTFILE "\n$created_line";

  close OUTFILE;


  $sql = 'select count(type) created, playername from `lb-'.$CFG::CFG{'world_name'}.'`, `lb-players` where date >= curdate() AND type = 0 AND `lb-players`.playerid = `lb-'.$CFG::CFG{'world_name'}.'`.playerid group by playername order by created desc limit 10';

  print "Executing Query:\n";

  print $sql."\n";

  $sth = $dbh->prepare($sql);
  $sth->execute();

  print "Writing to file:\n $CFG::CFG{'www_directory'}/lbschedstatsweb/data/$module_name/".$module_name."_destroyed_".getTodayStamp().".csv\n";

  open OUTFILE, ">", $CFG::CFG{'www_directory'}."/lbschedstatsweb/data/$module_name/".$module_name."_destroyed_".getTodayStamp().".csv" or die $!;

  print OUTFILE "$CFG::CFG{'world_name'},".getToday()."\n";
  print OUTFILE "Categories";

  my $destroyed_line = "Destroyed";

  while (my ($created, $playername) = $sth->fetchrow_array())
  {

    print OUTFILE ",$playername";
    $destroyed_line .= ",$created";

  }

  print OUTFILE "\n$destroyed_line";

  close OUTFILE;

  $dbh->disconnect();
}

################################################################################
# Module - Daily iConomy Stats By Hour
################################################################################

$module_name = 'daily_iconomy_stats_by_hour'; 

if ($CFG::CFG{'modules'}{'iconomy'}{$module_name} == 1) {

  $dbh = DBI->connect("DBI:mysql:database=$CFG::CFG{'modules'}{'iconomy'}{'ic_mysql_db'};host=$CFG::CFG{'modules'}{'iconomy'}{'ic_mysql_host'};port=$CFG::CFG{'modules'}{'iconomy'}{'ic_mysql_port'}", $CFG::CFG{'modules'}{'iconomy'}{'ic_mysql_usr'}, $CFG::CFG{'modules'}{'iconomy'}{'ic_mysql_pwd'}
             ) || die "Could not connect to database: $DBI::errstr";


  print "Running 'Daily iConomy Stats By Hour' Module...\n";
  
  $option_js .= "<option value='".$module_name.".htm'>Daily iConomy Stats by Hour</option>";  

  if(! -d $CFG::CFG{'www_directory'}."/lbschedstatsweb/data/$module_name") 
  { 
    mkdir $CFG::CFG{'www_directory'}."/lbschedstatsweb/data/$module_name" or die $!;
  }

  my $current_hour = getTodayHour();

  $sql = 'SELECT ROUND(AVG(balance)) avg_balance, ROUND(SUM(balance)) total_money FROM iConomy;'; 

  print "Executing Query:\n";

  print $sql."\n";

  $sth = $dbh->prepare($sql);
  $sth->execute();

  my $output_file = "$CFG::CFG{'www_directory'}/lbschedstatsweb/data/$module_name/".$module_name."_".getTodayStamp().".csv";

  my @total_data = ("Total $CFG::CFG{'modules'}{'iconomy'}{'major_currency'}",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
  my @avg_data = ("Avg. Account Size",0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);

  if (-e $output_file) {

    open INFILE, $output_file or die $!;

    my $line_count = 0;

    while(<INFILE>) {

      chomp();

      if($line_count == 2) {         
        @total_data = split /,/, $_;
      }

      if($line_count == 3) {         
        @avg_data = split /,/, $_;
      }

      $line_count++;
    }

    close INFILE;
  }

  print "Writing to file:\n $output_file\n";

  open OUTFILE, ">", $output_file or die $!;

  print OUTFILE "$CFG::CFG{'world_name'},".getToday()."\n";
  print OUTFILE "Categories,00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23\n";

  while (my ($avg_account, $total_money) = $sth->fetchrow_array()) {
    $avg_data[$current_hour + 1] = $avg_account;        
    $total_data[$current_hour + 1] = $total_money;        
  }

  $total_data[0] = "Total $CFG::CFG{'modules'}{'iconomy'}{'major_currency'}";

  print OUTFILE join(',', @total_data)."\n";
  print OUTFILE join(',', @avg_data);

  close OUTFILE;

  $dbh->disconnect();

}

# END of Modules

$option_js .= "</select>";

open OUTFILE, ">", $CFG::CFG{'www_directory'}."/lbschedstatsweb/options.js" or die $!;
print OUTFILE 'var RptOptions = "'.$option_js.'";'."\n";
print OUTFILE 'var MajorCurrency = "'.$CFG::CFG{'modules'}{'iconomy'}{'major_currency'}.'";'."\n";
close OUTFILE;

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
  my $mydate = "$mon/$mday/$year";
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
  my $mydate = $year.$mon.$mday;
  return $mydate;

}

sub getYesterdayStamp {

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time - 86400);
  $year=$year+1900;
  $mon=$mon+1;
  if($mon<10)
  {$mon="0$mon";}
  if($mday<10)
  {$mday="0$mday";}
  my $mydate = $year.$mon.$mday;
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
  my $mydate = "$year-$mon-$mday";
  return $mydate;

}

sub getTodayHour {

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  $year=$year+1900;
  $mon=$mon+1;
  if($mon<10)
  {$mon="0$mon";}
  if($mday<10)
  {$mday="0$mday";}
  my $mydate = $hour;
  return $mydate;

}


