#!perl
use strict;
use warnings;

use Cwd qw( getcwd );
use Perl::PrereqScanner;
use Path::Iterator::Rule;
use CPAN::Meta::Requirements;
use Data::Dumper;
my $reqs    = CPAN::Meta::Requirements->new();
my $pir     = Path::Iterator::Rule->new->skip_vcs->file->perl_module;
my $scanner = Perl::PrereqScanner->new(
    {
        scanners => [qw( Perl5 Moose TestMore POE Aliased )],
    }
);

for my $file ( $pir->all( getcwd . '/lib' ) ) {
    print "$file\n";
    $reqs->add_requirements( $scanner->scan_file($file) );
}
my $provides = do './bootstrap-provides.dump';
die "$!" if $?;
{
    open my $provided_fh, '<', 'provided.list'
      or die "Can't open provided.list";
    while ( my $package = <$provided_fh> ) {
        chomp $package;
        $package =~ s/#.*$//;
        next if $package =~ /^\s*$/;
        next if exists $provides->{$package};
        $provides->{$package} = 1;
    }
}

for my $req ( sort keys %{$provides} ) {
    $reqs->clear_requirement($req);
}
open my $fh, '>', 'bootstrap-prereqs.dump'
  or die "Can't open bootstrap-prereqs.dump";
print {$fh}
  Data::Dumper->new( [] )->Terse(1)->Sortkeys(1)->Indent(1)
  ->Values( [ $reqs->as_string_hash ] )->Dump;
close $fh;
