package MoobX::Scalar::Observable;
# ABSTRACT: Observable role for MobX scalars

=head1 DESCRIPTION

Role applied to L<MoobX::Scalar> objects to make them observables.

Used internally by L<MoobX>.

=cut

use 5.20.0;

use Moose::Role;

use Scalar::Util 'refaddr';

before 'FETCH' => sub {
    my $self = shift;
    push @MoobX::DEPENDENCIES, $self if $MoobX::WATCHING;
};

after 'STORE' => sub {
    my $self = shift;
    
    MoobX::observable_ref($self->value) if ref $self->value;
    MoobX::observable_modified( $self );
};

1;
