use strict;
use warnings;

use Test::More;
use Test::LongString;

use lib 't/lib';
use TestDOM 'Pod::PseudoPod::DOM::Role::HTML';
use File::Spec::Functions;
use File::Slurp;

use_ok( 'Pod::PseudoPod::DOM' ) or exit;

my $file   = read_file( catfile( qw( t test_file.pod ) ) );
my $result = parse_with_anchors( $file );

my $link   = encode_link( 'startofdocument' );
like_string $result, qr!<a name="$link"></a>!m,
    'Z<> tags should become anchors';

$link = encode_link( 'next_heading' );
like_string $result, qr!<a name="$link"></a>!m,
    '... without normal escaping';

$link = encode_link( 'slightlycomplex?heading' );
like_string $result, qr!<a name="$link"></a>!,
    '... and escaping non-alphanumerics';

like_string $result, qr!<a class="url" href="http://www.google.com/">!,
    'U<> tag should become urls';

$link = encode_link( 'startofdocument' );
like_string $result, qr!<a href="tags.t.pod#$link">!,
    'L<> tag should become cross references';

like_string $result, qr!<a href="tags.t.pod#$link">!,
    'A<> tag should become cross references';

$link = encode_link( 'slightlycomplex?heading' );
like_string $result, qr!<a href="tags.t.pod#$link">!,
    '... with appropriate quoting';

$link = encode_link( 'next_heading' );
like_string $result, qr!<a href="tags.t.pod#$link">!,
    '... and non-quoting when appropriate';

$link = encode_link( 'Specialformatting' );
like_string $result, qr!<p><a name="${link}1"></a>Special formatting!,
    '... paragraphs of index/anchor tags should collapse';

done_testing;
