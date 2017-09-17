#
# This file is part of Dist-Zilla-Plugin-Git
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Dist::Zilla::Role::Git::StringFormatter;
# ABSTRACT: Provide a String::Formatter for commit messages

our $VERSION = '2.042';

use 5.008;
use strict;
use warnings;

use namespace::autoclean;
use List::Util qw{ first };

use Moose::Role;
use MooseX::Has::Sugar;
use MooseX::Types::Moose qw{ Str };

requires qw(changelog log zilla);

use String::Formatter method_stringf => {
  -as => '_format_string_sub',
  codes => {
    c => sub { $_[0]->_get_changes },
    d => sub { require DateTime;
               DateTime->now(time_zone => $_[0]->time_zone)
                       ->format_cldr($_[1] || 'dd-MMM-yyyy') },
    n => sub { "\n" },
    N => sub { $_[0]->zilla->name },
    t => sub { $_[0]->zilla->is_trial
                   ? (defined $_[1] ? $_[1] : '-TRIAL') : '' },
    v => sub { $_[0]->zilla->version },
  },
};

#pod =attr changelog
#pod
#pod The filename of your F<Changes> file.  (Must be provided by the class
#pod that consumes this role.)
#pod
#pod =attr time_zone
#pod
#pod The time zone used with the C<%d> code.  The default is C<local>.
#pod
#pod =cut

has time_zone => ( ro, isa=>Str, default => 'local' );

around dump_config => sub
{
    my $orig = shift;
    my $self = shift;

    my $config = $self->$orig;
    $config->{+__PACKAGE__} = {
        time_zone => $self->time_zone,
    };

    return $config;
};

# -- private methods

# The sub generated by String::Formatter can't be used as a method directly.
sub _format_string
{
  my $self = shift;

  _format_string_sub(@_, $self);
} # end _format_string

sub _get_changes {
    my $self = shift;

    # parse changelog to find changes for this release
    my $cl_name   = $self->changelog;
    my $changelog = first { $_->name eq $cl_name } @{ $self->zilla->files };
    unless ($changelog) {
      $self->log("WARNING: Unable to find $cl_name");
      return '';
    }
    my $newver    = $self->zilla->version;
    $changelog->content =~ /
      ^\Q$newver\E(?![_.]*[0-9]).*\n # from line beginning with version number
      ( (?: (?> .* ) (?:\n|\z) )*? ) # capture as few lines as possible
      (?: (?> \s* ) ^\S | \z )       # until non-indented line or EOF
    /xm or do {
      $self->log("WARNING: Unable to find $newver in $cl_name");
      return '';
    };

    (my $changes = $1) =~ s/^\s*\n//; # Remove leading blank lines

    if (length $changes) {
      $changes =~ s/\s*\z/\n/; # Change trailing whitespace to a single newline
    } else {
      $self->log("WARNING: No changes listed under $newver in $cl_name")
    }

    # return changes
    return $changes;
} # end _get_changes

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::Git::StringFormatter - Provide a String::Formatter for commit messages

=head1 VERSION

version 2.042

=head1 DESCRIPTION

This role is used within the Git plugins to format strings that may
include the changes from the current release.

These formatting codes are available:

=over 4

=item C<%c>

The list of changes in the just-released version (read from C<changelog>).
It will include lines between the current version and timestamp and
the next non-indented line, except that blank lines at the beginning
or end are removed.  It always ends in a newline unless it is the empty string.

=item C<%{dd-MMM-yyyy}d>

The current date.  You can use any CLDR format supported by
L<DateTime>.  A bare C<%d> means C<%{dd-MMM-yyyy}d>.

=item C<%n>

a newline

=item C<%N>

the distribution name

=item C<%{-TRIAL}t>

Expands to -TRIAL (or any other supplied string) if this is a trial
release, or the empty string if not.  A bare C<%t> means C<%{-TRIAL}t>.

=item C<%v>

the distribution version

=back

=head1 ATTRIBUTES

=head2 changelog

The filename of your F<Changes> file.  (Must be provided by the class
that consumes this role.)

=head2 time_zone

The time zone used with the C<%d> code.  The default is C<local>.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Git>
(or L<bug-Dist-Zilla-Plugin-Git@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Git@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut