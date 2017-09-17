#!perl
use strict;
use warnings;

use Cwd qw( getcwd realpath );
use CPAN::DistnameInfo;

use constant SOURCEDIR => ( getcwd . '/dists-unpacked' );
use constant TARGETDIR => ( getcwd . '/lib' );

if ( !-e TARGETDIR ) {
    mkdir TARGETDIR or die "Can't make " . TARGETDIR;
}

open my $dist_fh, '<', 'dists.list' or die "Can't open dists.list";
while ( my $dist = <$dist_fh> ) {
    chomp $dist;
    $dist =~ s/#.*$//;
    next if $dist =~ /^\s*$/;
    my $info    = CPAN::DistnameInfo->new($dist);
    my $newname = $info->dist;
    my $indir   = SOURCEDIR . '/' . $newname;

    if ( not -e $indir ) {
        warn "* $indir does not exist, not unpacking\n";
        next;
    }
    opendir my $dh, "$indir/lib" or die "Can't copy libs from $indir";
    while ( my $node = readdir $dh ) {
        next if $node eq '.';
        next if $node eq '..';
        system( "cp", "-r", "-v", "-x", "-P", "-t", TARGETDIR,
            "$indir/lib/$node" ) == 0
          or die "Can't copy $indir/lib/$node";
    }
}
