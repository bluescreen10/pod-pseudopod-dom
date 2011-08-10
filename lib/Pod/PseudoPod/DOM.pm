package Pod::PseudoPod::DOM;
# ABSTRACT: an object model for Pod::PseudoPod documents

use strict;
use warnings;

use parent 'Pod::PseudoPod';
use Pod::PseudoPod::DOM::Elements;

sub new
{
    my ($class, %args)      = @_;
    my $role                = delete $args{formatter_role};
    my $self                = $class->SUPER::new(@_);
    $self->{class_registry} = {};
    $self->{formatter_role} = $role;

    $self->accept_targets( 'html', 'HTML' );
    $self->accept_targets_as_text(
        qw( author blockquote comment caution
            editor epigraph example figure important listing literal note
            production programlisting screen sidebar table tip warning )
    );

    $self->nix_X_codes(1);
    $self->nbsp_for_S(1);
    $self->codes_in_verbatim(1);

    return $self;
}

sub get_document
{
    my $self = shift;
    return $self->{Document};
}

sub make
{
    my ($self, $type, @args) = @_;
    my $registry             = $self->{class_registry};
    my $class                = $registry->{$type};

    unless ($class)
    {
        my $name = 'Pod::PseudoPod::DOM::Element::' . $type;
        $class   = $registry->{$type}
                 = $name->with_traits( $self->{formatter_role} );
    }

    return $class->new( @args );
}

sub start_Document
{
    my $self = shift;

    $self->{active_elements} =
    [
        $self->{Document} = $self->make( Document => type => 'document' )
    ];
}

sub end_Document
{
    my $self = shift;
    $self->{active_elements} = [];
}

sub reset_to_document
{
    my $self = shift;
    $self->{active_elements} = [ $self->{Document} ];
}

sub push_element
{
    my $self  = shift;
    my $child = $self->make( @_ );

    $self->{active_elements}[-1]->add_children( $child );
    push @{ $self->{active_elements } }, $child;
}

sub add_element
{
    my $self  = shift;
    my $child = $self->make( @_ );
    $self->{active_elements}[-1]->add( $child );
}

sub reset_to_item
{
    my ($self, $type, %attributes) = @_;
    my $elements                   = $self->{active_elements};
    my $class                      = 'Pod::PseudoPod::DOM::Element::' . $type;

    while (@$elements)
    {
        my $element = pop @$elements;
        next unless $element->isa( $class );

        # reset iterator
        my $attrs = keys %attributes;

        while (my ($attribute, $value) = each %attributes)
        {
            $attrs-- if $element->$attribute() eq $value;
        }

        return unless $attrs;
    }
}

BEGIN
{
    for my $heading ( 1 .. 4 )
    {
        my $start_meth = sub
        {
            my $self = shift;
            $self->reset_to_document;
            $self->push_element(
                Heading => level => $heading, type => 'header'
            );
        };

        my $end_meth = sub
        {
            my $self = shift;
            $self->reset_to_item( Heading => level => $heading );
        };

        do
        {
            no strict 'refs';
            *{ 'start_head' . $heading } = $start_meth;
            *{ 'end_head'   . $heading } = $end_meth;
        };
    }

    my %text_types =
    (
        Z => 'Anchor',
        I => 'Italics',
    );

    while (my ($tag, $type) = each %text_types)
    {
        my $start_meth = sub
        {
            my $self = shift;
            $self->push_element( 'Text::' . $type, type => lc $type );
        };

        my $end_meth = sub
        {
            my $self = shift;
            $self->reset_to_item( 'Text::' . $type, type => lc $type );
        };

        do
        {
            no strict 'refs';
            *{ 'start_' . $tag } = $start_meth;
            *{ 'end_'   . $tag } = $end_meth;
        };
    }
}

sub handle_text
{
    my $self = shift;
    $self->add_element( Text => type => 'text' );
    $self->add_element( 'Text::Plain' => type => 'text', content => shift );
}

sub start_Para
{
    my $self = shift;
    $self->push_element( Paragraph => type => 'paragraph' );
}

sub end_Para
{
    my $self = shift;
    $self->reset_to_item( Paragraph => type => 'paragraph' );
}

sub start_for
{
    my ($self, $flags) = @_;
    $self->push_element( Block => type => $flags->{target} || 'unknown_block' );
}

sub end_for
{
    my $self = shift;
    $self->reset_to_item( 'Block' );
}

1;
