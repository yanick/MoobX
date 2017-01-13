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
    MoobX::observable_modified( $self );
};

1;
