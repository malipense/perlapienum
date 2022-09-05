use strict;
use warnings;
use diagnostics;

my $ip_ver             = 4;
my $ip_len             = 5;
my $ip_ver_len         = $ip_ver . $ip_len;

print($ip_ver_len);