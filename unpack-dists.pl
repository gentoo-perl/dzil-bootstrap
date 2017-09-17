#!perl
use strict;
use warnings;

use Archive::Tar;
use Cwd qw( getcwd realpath );
use CPAN::DistnameInfo;

use constant SOURCEDIR => ( getcwd . '/dists' );
use constant TARGETDIR => ( getcwd . '/dists-unpacked' );

open my $dist_fh, '<', 'dists.list' or die "Can't open dists.list";
while ( my $dist = <$dist_fh> ) {
    chomp $dist;
    $dist =~ s/#.*$//;
    next if $dist =~ /^\s*$/;
    my $info    = CPAN::DistnameInfo->new($dist);
    my $newname = $info->dist . '.' . $info->extension;
    my $infile = SOURCEDIR . '/' . $newname; 

    if ( not -e $infile ) {
      warn "* $infile does not exist, not unpacking\n";
      next;
    }
    my $outdir = TARGETDIR .  '/' . $info->dist;
    if ( -e $outdir ) {
      $outdir = realpath($outdir);
      warn "* $outdir already exists, purging\n";
      if ( 30 > length $outdir or 3 > scalar split q[/], $outdir ) {
        warn "! $outdir TOO SUSPICIOUS, not removing\n";
        next
      }
      system("rm", "-r", "-v", $outdir ) == 0 or die "rm failed!";
    } 
    mkdir $outdir or die "Can't make $outdir";
    {
      my $ref = getcwd();
      chdir $outdir or die "Can't enter $outdir";
      system("tar", "-x", "-f", $infile , "--strip-components=1" );
      chdir $ref or die "Can't leave $outdir";
    }
}
