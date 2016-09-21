package MoobX;

use 5.20.0;

use MoobX::Observer;
use MoobX::Observable;

our @DEPENDENCIES;
our $WATCHING = 0;

use Scalar::Util qw/ reftype refaddr /;
use Moose::Util qw/ with_traits /;
use Module::Runtime 'use_module';

use experimental 'signatures';

use parent 'Exporter::Tiny';

our @EXPORT = qw/ observer observable /;

use Graph::Directed;

our $graph = Graph::Directed->new;

sub changing_observable($obs) {

    my @preds = $graph->all_predecessors( refaddr $obs );

    for my $pred ( @preds ) {
        my $info = $graph->get_vertex_attribute(
            $pred, 'info'
        );

        $info->clear_value;
    }
}

sub dependencies_for($self,@deps) {
    $graph->delete_edges(
        map { 
            refaddr $self => $_
        } $graph->successors(refaddr $self)
    );

    $graph->add_edges( 
        map { refaddr $self => refaddr $_ } @deps 
    );

    $graph->set_vertex_attribute(
        refaddr $_, info => $_ 
    ) for $self, @deps; 
}

sub observable :prototype(\[$%@]) {
    my $ref = shift;

    my $type = reftype $ref;

    my $class = 'MoobX::'.( $type || 'SCALAR' );

    $class = with_traits( 
        map { use_module($_) }
        map { $_, $_ . '::Observable' } $class
    );

    if( $type eq 'SCALAR' ) {
        tie $$ref, $class;
    }
    elsif( $type eq 'ARRAY' ) {
        tie @$ref, $class;
    }
    elsif( not $type ) {
        tie $ref, $class;
    }


    return $ref;

}

sub observer :prototype(&) { MoobX::Observer->new( generator => shift ) }

1;
