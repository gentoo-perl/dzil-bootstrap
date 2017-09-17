#!perl
use strict;
use warnings;

use Module::Metadata;
use Data::Dumper qw( Dumper );

my $provides = Module::Metadata->provides(
  dir => 'lib', version => 2,
);

local $Data::Dumper::Terse=1;
local $Data::Dumper::Indent=1;
open my $fh, '>', 'bootstrap-provides.json' or die "can't open bootstrap-provides.dump";
print {$fh} Dumper($provides);
close $fh;
