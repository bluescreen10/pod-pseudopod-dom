package Pod::PseudoPod::DOM::App::ToLaTeX;
# ABSTRACT: helper functions for bin/ppdom2latex

use strict;
use warnings;
use autodie;

use Pod::PseudoPod::DOM;
use Pod::PseudoPod::DOM::App qw( open_fh );

sub process_files_with_output
{
    for my $file ( @_ )
    {
        my ($source, $output) = @$file;

        my $parser  = Pod::PseudoPod::DOM->new(
            formatter_role => 'Pod::PseudoPod::DOM::Role::LaTeX',
            filename       => $output,
        );

        my $fh = open_fh( $output, '>' );
        $parser->output_fh($fh);

        $parser->no_errata_section(1); # don't put errors in doc output
        $parser->complain_stderr(1);   # output errors on STDERR instead

        die "Unable to open file\n" unless -e $source;
        $parser->parse_file( open_fh( $source ) );
        my $doc = $parser->get_document;
        print {$fh} $doc->emit;

        while (my ($name, $contents) = each %{ $doc->tables })
        {
            my $fh = open_fh( $name, '>' );
            print {$fh} $contents;
        }
    }
}

1;
