#!perl
use strict;
use warnings;

use HTTP::Tiny;
use Cwd qw( getcwd );
use CPAN::DistnameInfo;

use constant TARGETDIR => ( getcwd . '/dists' );

my $ua = HTTP::Tiny->new();
open my $dist_fh, '<', 'dists.list' or die "Can't open dists.list";

while ( my $dist = <$dist_fh> ) {
    chomp $dist;
    $dist =~ s/#.*$//;
    next if $dist =~ /^\s*$/;
    my $info    = CPAN::DistnameInfo->new($dist);
    my $newname = $info->dist . '.' . $info->extension;
    warn "Mirroring $dist to $newname\n";
    $ua->mirror( $dist, TARGETDIR . '/' . $newname );
}
