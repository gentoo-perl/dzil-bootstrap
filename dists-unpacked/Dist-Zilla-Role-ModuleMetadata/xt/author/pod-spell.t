use strict;
use warnings;
use Test::More;

# generated by Dist::Zilla::Plugin::Test::PodSpelling 2.007002
use Test::Spelling 0.12;
use Pod::Wordlist;


add_stopwords(<DATA>);
all_pod_files_spelling_ok( qw( bin lib examples lib script t xt ) );
__DATA__
irc
Karen
Etheridge
ether
lib
Dist
Zilla
Role
ModuleMetadata
