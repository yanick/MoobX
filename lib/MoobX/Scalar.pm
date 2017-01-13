package MoobX::Scalar; 
# ABSTRACT: MoobX wrapper for scalar variables

=head1 DESCRIPTION

Class implementing a C<tie>ing interface for scalar variables.

Used internally by L<MoobX>.

=cut

use Moose;

has value => (
    is     => 'rw',
    writer => 'STORE',
);

sub FETCH { $_[0]->value }

sub BUILD_ARGS {
    my( $class, @args ) = @_;

    unshift @args, 'value' if @args == 1;

    return { @args }
}

sub TIESCALAR { $_[0]->new( value => $_[1]) }

1;
