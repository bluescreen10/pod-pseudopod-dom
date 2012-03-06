package Pod::PseudoPod::DOM::Index;
# ABSTRACT: an index for a PPDOM Corpus

use strict;
use warnings;

use Moose;

has 'entries', is => 'ro', default => sub { {} };

sub add_entry
{
    my ($self, $node)        = @_;
    my ($title, @subentries) = split /\s*;\s*/, $node->emit_kids;
    my $entry                = $self->get_top_entry( $title );
    $entry->add( $title, @subentries, $node );
}

sub get_top_entry
{
    my ($self, $key) = @_;
    my $entries      = $self->entries;
    my $top_key      = uc substr $key, 0, 1;
    return $entries->{$top_key}
        ||= Pod::PseudoPod::DOM::Index::TopEntryList->new( key => $top_key );
}

sub emit_index
{
    my $self    = shift;
    my $entries = $self->entries;
    return join "\n", map { $entries->{$_}->emit } sort keys %$entries;
}

__PACKAGE__->meta->make_immutable;

package Pod::PseudoPod::DOM::Index::EntryList;

use strict;
use warnings;

use Moose;

has 'key',      is => 'ro', required => 1;
has 'contents', is => 'ro', default  => sub { {} };

sub add
{
    my ($self, $key) = splice @_, 0, 2;
    my $contents     = $self->contents;
    my $node         = pop @_;
    my $elements     = $contents->{$key} ||= [];

    # this is a nested entry
    if (@_)
    {
        my $entry_list = Pod::PseudoPod::DOM::Index::EntryList->new(
            key => shift @_,
        );
        $entry_list->add( @_, $node );
        push @{ $elements }, $entry_list;
    }
    else
    {
        my $entry = Pod::PseudoPod::DOM::Index::Entry->new( key => $key );
        $entry->add_location( $node );
        push @{ $elements }, $entry;
    }
}

sub emit
{
    my $self    = shift;
    my $key     = $self->key;
    return qq|<p>$key</p>\n|
         . $self->emit_contents;
}

sub emit_contents
{
    my $self     = shift;
    my $contents = $self->contents;
    my $content  = qq|<ul>\n|;

    for my $key (sort keys %$contents)
    {
        $content .= join "\n", map { '<li>' . $_->emit . '</li>' }
                                  @{ $contents->{$key} };
    }

    return $content . qq|</ul>\n|;
}

__PACKAGE__->meta->make_immutable;

package Pod::PseudoPod::DOM::Index::Entry;

use strict;
use warnings;

use Moose;

has 'key',       is => 'ro', required => 1;
has 'locations', is => 'ro', default  => sub { [] };

sub emit
{
    my $self = shift;
    my $key  = $self->key;
    return $key . ' ' . join ' ', map { $_->emit } @{ $self->locations };
}

sub add_location
{
    my ($self, $entry) = @_;
    push @{ $self->locations },
        Pod::PseudoPod::DOM::Index::Location->new( entry => $entry );
}

__PACKAGE__->meta->make_immutable;

package Pod::PseudoPod::DOM::Index::Location;
# ABSTRACT: represents a location to which an index entry points

use strict;
use warnings;

use Moose;

has 'entry', is => 'ro', required => 1;

sub emit
{
    my $self  = shift;
    my $entry = $self->entry;
    return '[' . $entry->emit_index_link . ']';
}

__PACKAGE__->meta->make_immutable;

package Pod::PseudoPod::DOM::Index::TopEntryList;

use strict;
use warnings;

use Moose;

extends 'Pod::PseudoPod::DOM::Index::EntryList';

sub emit
{
    my $self = shift;
    my $key  = $self->key;
    return qq|<h2>$key</h2>\n\n| . $self->emit_contents;
}

__PACKAGE__->meta->make_immutable;
