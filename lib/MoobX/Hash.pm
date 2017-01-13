package MoobX::Hash;

use Moose;

use experimental 'postderef';

has value => (
    traits => [ 'Hash' ],
    is => 'rw',
    default => sub { +{} },
    handles => {
        FETCH => 'get',
        STORE => 'set',
        CLEAR => 'clear',
        DELETE => 'delete',
        EXISTS => 'exists',
    },
);

sub BUILD_ARGS {
    my( $class, @args ) = @_;

    unshift @args, 'value' if @args == 1;

    return { @args }
}

sub TIEHASH { 
    (shift)->new( value => +{ @_ } ) 
}

sub FIRSTKEY { my $self = shift; my $a = scalar keys $self->value->%*; each $self->value->%* }
sub NEXTKEY  { my $self = shift; each $self->value->%* }



1;
