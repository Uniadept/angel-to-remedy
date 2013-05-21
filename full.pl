#!/usr/bin/perl -w
#full.pl - Angel page 2245

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

my $USERNAME  = "oit-angel";
my $PASSWORD  = "angeldev";
 
my $arServer = "ars00srv";
my $arwebServer = "remedyservice.oit.ncsu.edu";
my $ServiceName  = "customers";
my $RemedyURL    = "http://".$arwebServer."/arsys/services/ARService?server=".$arServer."&webService=".$ServiceName;
my $RemedyNS     = "urn:".$ServiceName;

my @nowTime = localtime(time);
my $year = $nowTime[5] + 1900;
my $mon = $nowTime[4]+1;
my $mday = $nowTime[3];

($year, $mon, $mday) = Add_Delta_Days($year, $mon, $mday, -5);
my $remedyDate = "%22+AND+%27Modified-date%27%3e%3d%22$mon%2f$mday%2f$year%22";
 
my $userEx = "919-515-0290";
my $StatusTxt = "Success";
my $UpdateDate = "2012-06-21T14:35:11";
 
my $soap = SOAP::Lite
    -> proxy($RemedyURL)
    -> ns($RemedyNS,'ns1')
    -> autotype(0)
    -> readable(1);
 
my $header = SOAP::Header->name('AuthenticationInfo' => 
	\SOAP::Header->value(
		SOAP::Header->name('userName' => $USERNAME)->type(''),
		SOAP::Header->name('password' => $PASSWORD)->type('') ));

$campus = "919-51";
if ($values[0] =~ /^(5-([0-9]{4}))$/ ) {
	$userEx1 = $campus . $values[0];
} elsif($values[0] =~ /^[53][0-9]{4}$/) {
	substr($values[0],1,0,"-");
	$userEx1 = $campus . $values[0];
  } else {$userEx1 = $values[0];} 
if ($values[0] =~ /^[0-9]{10}$/ ){
        substr($values[0],3,0,"-");
        substr($values[0],7,0,"-");
        $userEx1 = $values[0];
}
#$userEx1 = $values[0];
#$msg .= "phone is: $userEx1 \n";

my $data = SOAP::Data->name('phone')->value($userEx1);

my $thisName = "get-entry-by-phone";
my $som=$soap->$thisName($header,$data);

#Check for fault
if ($som->fault){
my $errorString = $som->faultstring;
$msg .= "Fault : $errorString ";
write_log($msg);
print <<xmls;

<ANGELXML>
  <VARIABLES>
    <VAR name="RemedyDate" value="$remedyDate"/>
    <VAR name="Rem_Name" value="Phone wrong"/>
  </VARIABLES>
  <MESSAGE>
    <PLAY>
      <PROMPT type="text">.</PROMPT>
    </PLAY>
    <GOTO destination="/2300" />
  </MESSAGE>
</ANGELXML>
xmls
exit;
}

$msg .= "What I was sent $values[0] ";
$msg .= "What I sent to Remedy $userEx1 ";
my $cookiesfirst = $som->valueof('//get-entry-by-phoneResponse/firstname');
my $cookieslast = $som->valueof('//get-entry-by-phoneResponse/lastname');
my $CID = $som->valueof('//get-entry-by-phoneResponse/cid');
#$msg .= "I am adding strings $userEx1";
$msg .= "CID is $CID ";
$msg .= "Name is: $cookiesfirst $cookieslast ";

write_log($msg);

my $testvar = "$cookiesfirst $cookieslast";

print <<xmls;

<ANGELXML>
  <VARIABLES>
    <VAR name="Rem_Name" value="$testvar"/>
    <VAR name="CampusID" value="$CID"/>
    <VAR name="RemedyDate" value="$remedyDate"/>
  </VARIABLES>
  <QUESTION>
    <PLAY>
      <PROMPT type="text">Are you , , $testvar , , Press 1 for yes and 2 for no.</PROMPT>
    </PLAY>
   <RESPONSE>
    <KEYWORD>
	<LINK keyword="Yes,1" dtmf="1" returnValue="AGREE" destination="/2380" />
	<LINK keyword="No,2" dtmf="2" returnValue="DISAGREE" destination="/2290" />
    </KEYWORD>
   </RESPONSE>
  </QUESTION>
</ANGELXML>
xmls
exit;
