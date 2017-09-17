#!perl
use strict;
use warnings;

use HTTP::Tiny;
use YAML::XS qw( Load );
use constant ENDPOINT => 'http://cpanmetadb.plackperl.org/v1.0/package/';
use constant DLPREFIX => 'https://cpan.metacpan.org/authors/id/';

my $ua = HTTP::Tiny->new();

my %ignore    = ();
{
  open my $provided_fh, '<', 'provided.list' or die "Can't open provided.list";
  while ( my $package = <$provided_fh> ) {
    chomp $package;
    $package =~ s/#.*$//;
    next if $package =~ /^\s*$/;
    $ignore{$package} = 1
  }
}
open my $package_fh, '<', 'packages.list' or die "Can't open packages.list";

my %downloads = ();
my %provides  = ();
my %seen      = ();

while ( my $package = <$package_fh> ) {
    chomp $package;
    $package =~ s/#.*$//;
    next if $package =~ /^\s*$/;
    next if $seen{$package}++;
    next if is_provided($package);

    my $content = get_distmeta($package);

    my $distfile = $content->{distfile};
    my $provided = $content->{provides};

    $downloads{$distfile} = $distfile;
    warn "$package -> $distfile\n";

    for my $ppackage ( sort keys %$provided ) {
        register_provide( $ppackage, $provided->{$ppackage}, $distfile );
    }
}
open my $dist_fh, '>', 'dists.list' or die "Cant write dists.list";

for my $package ( sort keys %downloads ) {
  $dist_fh->printf("%s%s\n", DLPREFIX, $package );
}

sub is_provided {
    my ( $package_name ) = @_;
    return exists $provides{$package_name} || exists $ignore{$package_name};
}
sub get_distmeta {
    my ($package_name) = @_;
    my $response = $ua->get( ENDPOINT . $package_name );
    if ( not $response->{success} ) {
        warn "Failed to resolve $package_name\n";
        return;
    }
    my $content;
    eval { $content = Load( $response->{content} ); 1 } || return;

    return $content;
}

sub register_provide {
    my ( $package_name, $version, $distname ) = @_;
    if ( not defined $version ) {
        warn "${package_name}'s version is undef in $distname";
        $version = 0;
    }
    if ( not exists $provides{$package_name} ) {
        $provides{$package_name} = { $version => [$distname] };
        return;
    }
    my $existing = $provides{$package_name};
    my (@strings);

    for my $version ( sort { version->parse($a) <=> version->parse($b) }
        keys %{$existing} )
    {
        push @strings, " - $version => [ "
          . ( join q[, ], sort @{ $existing->{$version} } ) . " ]";
    }
    warn "$package_name already provided:\n" . ( join qq[\n], @strings ) . "\n";

    push @{ $existing->{$version} }, $distname;

}
