package MoobX::Scalar::Observable;

use 5.20.0;

use Moose::Role;

use Scalar::Util 'refaddr';

before 'FETCH' => sub {
    my $self = shift;
    push @MoobX::DEPENDENCIES, $self if $MoobX::WATCHING;
};

after 'STORE' => sub {
    my $self = shift;
    $DB::single = 1;
    
    MoobX::observable_ref($self->value) if ref $self->value;
    MoobX::observable_modified( $self );
};

1;
