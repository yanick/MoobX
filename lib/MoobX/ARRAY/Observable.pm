package MoobX::ARRAY::Observable;

use Moose::Role;

use experimental 'postderef', 'signatures';

use Scalar::Util 'refaddr';

before [ qw/ FETCH FETCHSIZE /] => sub {
    my $self = shift;
    push @MoobX::DEPENDENCIES, $self if $MoobX::WATCHING;
};


around STORE => sub($orig,$self,$index,$value) {
    if( ref $value and ! tied $value ) {
        my @old = @$value;
        ::observable($value);
        push @$value, @old;
    }
    $orig->($self,$index,$value);
};

after [ qw/ STORE PUSH CLEAR /] => sub {
    my $self = shift;
#        ::observable($_) for grep { ! tied $_ } grep { ref  } $self->value->@*;
    MoobX::changing_observable( $self );
};



1;
