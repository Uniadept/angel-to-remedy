#!/usr/bin/perl -w
#full.pl - Angel page 2245

#
# Hi Andrew
#

use CGI;
use XML::Simple;
use Env;
use SOAP::Lite;
use Encode;
use Time::Local;
use Date::Calc qw(Add_Delta_Days);
use File::Basename qw(direname);
require (dirname($0) . "/ars_common.pl");

use vars qw($ars_host 
      $ars_user
	    $ars_pass
	    $arwebServer
	    $ars_serv);

my $q = CGI->new();

my $msg = "";
$msg .= "full.pl ";

@values = $q->param('CallerID');

$msg .= "CGI variables passed: ";
foreach my $v ($q->param) {
    $msg .= "$v = '" . $q->param($v) . "' ";
}
$msg .= "";

#Write to log
sub write_log {
        my $arLogFile = "/afs/unity/web/r/remedy/htdocs/angel_logs/Remedy_Count.Log";
	#my $arLogFile = "/home/www/angel_logs/Remedy_Count.Log";
        my($message) = @_;
        $message = "$message";
        #chop(my $date = `date +'%a %b %e %Y %T'`);
	chop(my $date = `date +'%Y-%m-%d %T'`);
        warn "Could not open logfile: $arLogFile\n" unless (open(LOGFILE, ">>$arLogFile"));
        print LOGFILE "$date $message\n";
        warn "Could not Close logfile: $arLogFile\n" unless (close(LOGFILE));
}#Log stuff!
