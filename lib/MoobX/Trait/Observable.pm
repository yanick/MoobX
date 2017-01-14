package MoobX::Trait::Observable;
# ABSTRACT: turn a Moose object attribute into an MoobX observable

=head1 SYNOPSIS

    package Person;

    use MoobX;

    our $OPENING :Observable = 'Dear';

    has name => (
        traits => [ 'Observable' ],
        is     => 'rw',
    );

    has address => (
        is      => 'ro',
        traits  => [ 'Observer' ],
        default => sub {
            my $self = shift;
            join ' ', $Person::OPENING, $self->name
        },
    );

    my $person = Person->new( name => 'Wilfred' );

    print $person->address;  # Dear Wilfred

    $person->name( 'Wilma' );

    print $person->address;  # Dear Wilma

=head1 DESCRIPTION

Turns an object attribute into an observable.

=cut

use Moose::Role;
use MoobX;
use Moose::Util;

Moose::Util::meta_attribute_alias('Observable');

use experimental 'signatures';

after initialize_instance_slot => sub($attr_self,$,$instance,$) {

    $instance->meta->add_before_method_modifier( $attr_self->get_read_method, sub($self,@) {
        push @MoobX::DEPENDENCIES, $attr_self if $MoobX::WATCHING;
    }) if $attr_self->has_read_method;

    $instance->meta->add_after_method_modifier( $attr_self->get_write_method, sub {
        my( $self, $value ) = @_;
        MoobX::observable_ref($value) if ref $value;
        MoobX::observable_modified( $attr_self );
    }) if $attr_self->has_write_method;

};

1;
