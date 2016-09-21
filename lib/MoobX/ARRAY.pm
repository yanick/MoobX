package MoobX::ARRAY;

use Moose;

has value => (
    traits => [ 'Array' ],
    is => 'rw',
    default => sub { [] },
    handles => {
        FETCHSIZE => 'count',
        CLEAR     => 'clear',
        STORE     => 'set',
        FETCH     => 'get',
        PUSH      => 'push',
    },
);

sub EXTEND {
}

before CLEAR => sub { warn @_ };

sub STORESIZE { }

sub BUILD_ARGS {
    my( $class, @args ) = @_;

    unshift @args, 'value' if @args == 1;

    return { @args }
}

sub TIEARRAY { 
    (shift)->new( value => [ @_ ] ) 
}


1;
