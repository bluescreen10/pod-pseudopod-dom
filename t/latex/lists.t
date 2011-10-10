use strict;
use warnings;

use Test::More;
use Test::LongString;

use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::LaTeX';
use File::Spec::Functions;
use File::Slurp;

use_ok( 'Pod::PseudoPod::DOM' ) or exit;

my $file   = read_file( catfile( qw( t latex test_file.pod ) ) );
my $result = parse( $file );

like_string $result, qr!normal numbered lists:\n\n\\begin{enumerate}!,
    'numbered lists should translate to \\begin{enumerate}';

like_string $result,
    qr!\\item Something\.\n\n\\item Or\.\n\n\\item Other\.\n\n\\end{enumerate}!,
    '... and should use bare \\item';

done_testing;