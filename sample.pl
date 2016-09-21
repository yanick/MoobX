use 5.20.0;

use experimental 'signatures';

package MoobX {
    our @DEPENDENCIES;
    our $WATCHING = 0;

    use Scalar::Util 'refaddr';
    use experimental 'signatures';

    use Graph::Directed;

    our $graph = Graph::Directed->new;

    sub node_name($node) { join '!', @$node }

    sub changing_observable($obs) {
        my @preds = $graph->all_predecessors( node_name($obs) );

        for my $pred ( @preds ) {
            my $info = $graph->get_vertex_attribute(
                $pred, 'info'
            );

            my( $obj, $attr ) = @$info;
            my $clearer = $obj->meta->get_attribute($attr)->clearer;
            $obj->$clearer;
        }

    }

    sub dependencies_for($self,@deps) {
        $graph->delete_edges(
            map { 
                node_name( $self ) => $_
            } $graph->successors(node_name($self))
        );

        $graph->add_edges( 
            map { node_name($self) => node_name($_) } @deps 
        );

        $graph->set_vertex_attribute(
            node_name($_), info => $_ 
        ) for $self, @deps; 
    }
}

package Observable {
    use Moose::Role;

    use Scalar::Util 'refaddr';

    #before [ 'get_value', '_inline_get_value', '_inline_init_from_default', '_inline_generate_default' ] => sub {
    after initialize_instance_slot => sub {
        my( $self, $meta, $instance, $params ) = @_;

        $instance->meta->add_before_method_modifier( $self->get_read_method, sub {
            push @MoobX::DEPENDENCIES, [ $instance, $self->name ] if $MoobX::WATCHING;
        });

        $instance->meta->add_after_method_modifier( $self->get_write_method, sub {
                MoobX::changing_observable( [ $instance, $self->name ] );
        });
    };


}

package Observer {
    use Moose::Role;

    use Scalar::Util qw/ refaddr /;

    after initialize_instance_slot => sub {
        my( $self, $meta, $instance, $params ) = @_;

        $instance->meta->add_method(
            'dependencies_' . $self->name, sub {
                map { $MoobX::graph->get_vertex_attribute($_, 'info') }
                $MoobX::graph->successors( MoobX::node_name([ $instance, $self->name]));
            }
        );
    };

    before _process_options => sub {
        my( $class, $name, $params ) = @_;

        my $default = $params->{default};

        $params->{default} = sub {
            local $MoobX::WATCHING = 1;
            local @MoobX::DEPENDENCIES;

            my $self = shift;

            my $new_value = $default->($self);

            MoobX::dependencies_for( [ $self => $name ], @MoobX::DEPENDENCIES );

            return $new_value;
        };
    };


}

package Person {

    use Moose;

    has address => (
        is => 'ro',
        traits => [ 'Observer' ],
        lazy => 1,
        clearer => 'clear_baz',
        default => sub { 
            my $self = shift;
            join ' ', $self->title || $self->name->first, $self->name->last;
        },
    );

    has name => (
        is => 'ro',
        default => sub { Name->new },
    );

    has title => (
        traits => [ 'Observable' ],
        is => 'rw',
    );
}

package Name {

    use Moose;

    has [ qw/ first last /] => (
        is => 'rw',
        traits => [ 'Observable' ],
    );

}

my $foo = Person->new( name => Name->new( first => 'Yanick', last => 'Champoux' ) );

say $foo->address;  # Yanick Champoux

$foo->title( 'Dread Lord' );

say $foo->address;

for my $dep ($foo->dependencies_address ) {
    my( $obj, $attr ) = @$dep;
    say $obj . '->' . $attr, ' = ', $obj->$attr;
}
