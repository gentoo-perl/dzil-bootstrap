#!perl
use strict;
use warnings;

my $version = do {
    open my $fh, '<', "VERSION" or die "Can't read VERSION";
    local $/;
    scalar <$fh>;
};
chomp $version;

my $PNV = 'dzil-bootstrap-' . $version;
my $TAR = $PNV . '.tar';

system(
    'tar',                    '-v',
    '-c',                     '-f',
    $TAR,                     '--transform=s|^|' . $PNV . '/|',
    'bootstrap-prereqs.dump', 'bootstrap-provides.dump',
    'dists.list',             'lib',
    'VERSION'
  ) == 0
  or die "Cant make tar";

system(
    'xz', '-vv9e',
    '--lzma2=dict=512KiB,lc=3,lp=0,pb=2,mode=normal,nice=273,mf=bt4,depth=2048',
    '--memlimit-decompress=1M',    # low threshold for decompressing.
    '-k', $TAR
  ) == 0
  or die "Can't xz";
system( 'lzip', '-9', '-v', '--dictionary-size=1M', '-k', $TAR ) == 0
  or die "Can't lz";
system( 'zopfli', '-v', '--i100', $TAR ) == 0 or die "Can't zopfli";

