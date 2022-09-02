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

Options:

-h          show help manual
-hl         list all response headers
....
USAGE

getopts('UMNSPGlLDu:dp:f:rR:s:k:vAow:hnaiPK:', \%opts);


my $target = shift or die $MANUAL;
print("Sending request to: $target\n\n");
# if ($target =~ /^([a-zA-Z0-9\._\-]+)$/) {
# 	$target = $1;
#     print($target);
# } else {
# 	print "ERROR: Target hostname \"$target\" contains some illegal characters\n";
# 	exit 1;
# }

# Print help message if required
if ($opts{'h'}) {
	print $MANUAL;
	exit 0;
}
#https://api.github.com/
my $request = HTTP::Request->new('GET' => $target);
my $ua = LWP::UserAgent->new();

my $response = $ua->request($request);
print($response->headers()->as_string);




