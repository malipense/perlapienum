use strict;
use warnings;
use diagnostics;

use feature 'say';
use feature 'switch';
use Term::ANSIColor;
use Getopt::Std;

require HTTP::Request;
require LWP::UserAgent;

my %opts;
my $VERSION = "0.0.1";
my $MANUAL = <<USAGE;

apienum v$VERSION
In theory all this script will do is send a request to a website
and output information about the host.
I will prolly extend its functionalities once I get more used to 
the language. 
For now I'm starting with the basics.

I started investigating the use of HTTP::Request, but it abstracts a lot of things
that I need to have access to it, so I started looking for how to create a TCP/IP
package from scratch, after that what I need to know prolly is how to add the HTTP
protocol headers on top of it, and I believe it should work. 

The code is the one provided by cleen, available here:https://www.perlmonks.org/?node_id=17576

Options:

-h          show help manual
-hl         list all response headers
....
USAGE

getopts('UMNSPGlLDu:dp:f:rR:s:k:vAow:hnaiPK:', \%opts);
#*******************************************************#
# my $target = shift or die $MANUAL;
# print("Sending request to: $target\n\n");

# # Print help message if required
# if ($opts{'h'}) {
# 	print $MANUAL;
# 	exit 0;
# }
# #https://api.github.com/
# my $request = HTTP::Request->new('GET' => $target);
# my $ua = LWP::UserAgent->new();

# my $response = $ua->request($request);
# print($response->headers()->as_string);
#********************************************************#

use Socket;


sub createtcpipheaders
{
	our($src_ip_address, $src_port, $dst_ip_address, $dst_port) = @_;

	my $zero_cksum = 0;

	my $tcp_proto = 6;
	my ($tcp_length) = 20;
	my $syn = 13456;
	my $ack = 0;
	my $tcp_header_length = "5";
	my $tcp_reserved = 0;
	my $tcp_head_reserved = $tcp_header_length . $tcp_reserved;

	#flags
	my $tcp_urgent            = 0;
	my $tcp_acknowledgment    = 0;
	my $tcp_push              = 0;
	my $tcp_reset             = 0;
	my $tcp_syn 			  = 1;
	my $tcp_fin 			  = 0;
	my $null 				  = 0;
	my $tcp_window_size 	  = 124;
	my $tcp_urgent_ptr 		  = 0;
	my $tcp_all = $null . $null . $tcp_urgent . $tcp_acknowledgment . $tcp_push . $tcp_reset . $tcp_syn . $tcp_fin;

	my ($tcp_pseudo_header) = pack('a4a4CCnnnNNH2B8nvn',
	$tcp_length, $src_port, $dst_port, $syn, $ack,
	$tcp_head_reserved, $tcp_all, $tcp_window_size, $null, $tcp_urgent_ptr);

	my ($tcp_checksum) = &checksum($tcp_pseudo_header);

	# Now lets construct the IP packet
	my $ip_version         = 4;
	my $ip_length          = 5;
	my $ip_version_length  = $ip_version . $ip_length;
	my $ip_typeofservice   = 00;
	my ($ip_total_length)  = $tcp_length + 20;
	my $ip_frag_id         = 19245;
	my $ip_frag_flag       = 0x40;
	my $ip_frag_oset       = "0000000000000";
	my $ip_fl_fr           = $ip_frag_flag . $ip_frag_oset;
	my $ip_ttl             = 128;

	# Lets pack this baby and ship it on out!
 	my ($pkt) = pack('H2H2nnB16C2na4a4nnNNH2B8nvn',
	$ip_version_length, $ip_typeofservice, $ip_total_length, $ip_frag_id,
	$ip_fl_fr, $ip_ttl, $tcp_proto, $zero_cksum, $src_ip_address,
	$dst_ip_address, #end of ip packet
	
	
	$src_port, $dst_port, $syn, $ack, $tcp_head_reserved,
	$tcp_all, $tcp_window_size, $tcp_checksum, $tcp_urgent_ptr);

 	return $pkt;
}
sub checksum {
 # This of course is a blatent rip from _the_ GOD,
 # W. Richard Stevens.
  
 my ($msg) = @_;
 my ($len_msg,$num_short,$short,$chk);
 $len_msg = length($msg);
 $num_short = $len_msg / 2;
 $chk = 0;
 foreach $short (unpack("S$num_short", $msg)) {
  $chk += $short;
 }
 $chk += unpack("C", substr($msg, $len_msg - 1, 1)) if $len_msg % 2;
 $chk = ($chk >> 16) + ($chk & 0xffff);
 return(~(($chk >> 16) + $chk) & 0xffff);
}

my $src_host = "www.google.com";
my $dst_host = "www.downloadcult.org"; 
my $dst_port = 80;
my $src_port = 55489;


print("running\n");
my $dst_ip_address = gethostbyname($dst_host);
my $src_ip_address = gethostbyname($src_host);
print(inet_ntoa($src_ip_address)."\n");
print(inet_ntoa($dst_ip_address)."\n");

socket(RAW, AF_INET, SOCK_RAW, 255) || die $!;
setsockopt(RAW, 0, 1, 1);

my ($packet) = createtcpipheaders($src_ip_address, $src_port, $dst_ip_address, $dst_port);

my ($destination) = pack('Sna4x8', AF_INET, $dst_port, $dst_ip_address);
send(RAW,$packet,0,$destination);
print("packge sent!");