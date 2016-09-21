use 5.20.0;

use Scalar::Util 'reftype';

package MoobX {
    our @DEPENDENCIES;
    our $WATCHING = 0;

    use Scalar::Util 'refaddr';

    use Graph::Directed;

    our $graph = Graph::Directed->new;

    use experimental 'signatures';

    sub changing_observable($obs) {
        warn "$obs changing";
        my @preds = $graph->all_predecessors( refaddr $obs );

        for my $pred ( @preds ) {
            warn "\t$pred";
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
}


package MoobX::Observer {
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

    has generator => (
        required => 1,
    );

    use Scalar::Util 'refaddr';
    use experimental 'signatures';

    sub dependencies($self) {
        [ map {
            $MoobX::graph->get_vertex_attribute( $_, 'info' );
            } $MoobX::graph->successors( refaddr($self) ) ]
    }

    sub _build_value {
        my $self = shift;

        local $MoobX::WATCHING = 1;
        local @MoobX::DEPENDENCIES;

        my $new_value = $self->generator->();

        MoobX::dependencies_for( $self, @MoobX::DEPENDENCIES );

        return $new_value;
    }
}

package MoobX::SCALAR {
    use Moose;

    has value => (
        is => 'rw',
        reader => 'FETCH',
        writer => 'STORE',
    );

    sub BUILD_ARGS {
        my( $class, @args ) = @_;

        unshift @args, 'value' if @args == 1;

        return { @args }
    }

    sub TIESCALAR {$_[0]->new( value => $_[1]) }
}

package MoobX::ARRAY {
    use Moose;

    has value => (
        traits => [ 'Array' ],
        is => 'rw',
        default => sub { [] },
        handles => {
            FETCHSIZE => 'count',
            CLEAR => 'clear',
            STORE => 'set',
            FETCH => 'get',
            PUSH => 'push',
        },
    );

    sub EXTEND {
    }

    sub STORESIZE { warn @_ }

    sub BUILD_ARGS {
        my( $class, @args ) = @_;

        unshift @args, 'value' if @args == 1;

        return { @args }
    }

    sub TIEARRAY { 
        warn @_;
        (shift)->new( value => [ @_ ] ) 
    }
}

package MoobX::SCALAR::Observable {
    use Moose::Role;

    use Scalar::Util 'refaddr';

    before 'FETCH' => sub {
        my $self = shift;
        push @MoobX::DEPENDENCIES, $self if $MoobX::WATCHING;
    };

    after 'STORE' => sub {
        my $self = shift;
        MoobX::changing_observable( $self );
    };
}

package MoobX::ARRAY::Observable {
    use Moose::Role;

    use Scalar::Util 'refaddr';

    before [ qw/ FETCH FETCHSIZE /] => sub {
        my $self = shift;
        push @MoobX::DEPENDENCIES, $self if $MoobX::WATCHING;
    };

    use experimental 'postderef', 'signatures';

    around STORE => sub($orig,$self,$index,$value) {
        warn $value;
        if( ref $value and ! tied $value ) {
            my @old = @$value;
            ::observable($value);
            push @$value, @old;
        }
        warn $value;
        $orig->($self,$index,$value);
    };

    after [ qw/ STORE PUSH CLEAR /] => sub {
        my $self = shift;
#        ::observable($_) for grep { ! tied $_ } grep { ref  } $self->value->@*;
        MoobX::changing_observable( $self );
    };

}

use Moose::Util qw/ with_traits /;

sub observable (+) {
    my $ref = shift;

    my $type = reftype $ref;

    my $class = 'MoobX::'.( $type || 'SCALAR' );

    $class = with_traits( $class, $class . '::Observable' );

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

sub observer (&) {
    return MoobX::Observer->new(
        generator => shift,
    );
}

observable my $first_name;
observable my $last_name;
observable my $title;

my $address = observer {
    join ' ', $title || $first_name, $last_name;
};

observable my @things;

my $list = observer {
    use DDP; p @things;
    join ' ', map @$_, @things;
};

say $list;
say "first one";

use DDP;
p $list->dependencies;

@things = ( [1],[2],[3]);

say '!',@things;
say $list;

push @things, [4];
say @things;

say $list;

$things[0][0] = 5;

say $list;

__END__

print $address;

$first_name = "Yanick";
$last_name = "Champoux";

say $address;

use Data::Printer;
p $address->dependencies;

$title = 'Dread Lord';

say $address;

use Data::Printer;
#p $address->dependencies;
