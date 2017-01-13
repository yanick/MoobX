package MoobX::ARRAY::Observable;

use Moose::Role;

use experimental 'postderef', 'signatures';

use Scalar::Util 'refaddr';

before [ qw/ FETCH FETCHSIZE /] => sub {
    my $self = shift;
    push @MoobX::DEPENDENCIES, $self if $MoobX::WATCHING;
};


after [ qw/ STORE PUSH CLEAR /] => sub {
    my $self = shift;
    for my $i ( 0.. $self->value->$#* ) {
        next if tied $self->value->[$i];
        next unless ref $self->value->[$i] eq 'ARRAY';
        MoobX::observable( @{ $self->value->[$i] } );
    }
    MoobX::observable_modified( $self );
};



1;
