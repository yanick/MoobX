package MoobX::Observer;

use 5.20.0;

use Moose;

use overload 
    '""' => sub { $_[0]->value },
    fallback => 1;

use MooseX::MungeHas 'is_ro';

has value => ( 
    builder => 1,
    lazy => 1,
    predicate => 1,
    clearer => 1,
);

after clear_value => sub {
    my $self = shift;
    $self->value if $self->autorun;
};

has generator => (
    required => 1,
);

has autorun => ( is => 'ro', trigger => sub {
    $_[0]->value
});

use Scalar::Util 'refaddr';
use experimental 'signatures';

sub dependencies($self) {
     map {
        $MoobX::graph->get_vertex_attribute( $_, 'info' );
        } $MoobX::graph->successors( refaddr($self) ) 
}

sub _build_value {
    my $self = shift;

    local $MoobX::WATCHING = 1;
    local @MoobX::DEPENDENCIES;

    my $new_value = $self->generator->();

    MoobX::dependencies_for( $self, @MoobX::DEPENDENCIES );

    return $new_value;
}

1;
