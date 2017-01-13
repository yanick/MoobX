package MoobX;
# ABSTRACT: Reactive programming framework heavily inspired by Javascript's MobX

=head1 SYNOPSIS

    use 5.20.0;

    use Data::Printer;

    use MoobX;

    observable my $first_name;
    observable my $last_name;
    observable my $title;

    my $address = observer {
        join ' ', $title || $first_name, $last_name;
    };

    observable my @things;

    say $address;  # nothing

    $first_name = "Yanick";
    $last_name = "Champoux";

    say $address;  # Yanick Champoux

    $title = 'Dread Lord';

    say $address;  # Dread Lord Champoux

=head1 DESCRIPTION

As I was learning how to use L<https://github.com/mobxjs/mobx|MobX>, I thought
it'd be fun to try to implement something similar in Perl. So I did. 

To have an idea of the mechanics of MoobX, see the two blog entries in the SEE ALSO
section.



=head1 SEE ALSO

=over

=item L<https://github.com/mobxjs/mobx|MobX> - the original inspiration

=item L<http://techblog.babyl.ca/entry/moobx> and L<http://techblog.babyl.ca/entry/moobx-2> - the two blog entries that introduced MobX.
    

=back



=cut

use 5.20.0;

use MoobX::Observer;
use MoobX::Observable;

our @DEPENDENCIES;
our $WATCHING = 0;

use Scalar::Util qw/ reftype refaddr /;
use Moose::Util qw/ with_traits /;
use Module::Runtime 'use_module';
use Graph::Directed;

use experimental 'signatures';

use parent 'Exporter::Tiny';

our @EXPORT = qw/ observer observable autorun /;

our $graph = Graph::Directed->new;

sub observable_modified($obs) {

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
        my $value = $$ref;
        tie $$ref, $class;
        $$ref = $value;
    }
    elsif( $type eq 'ARRAY' ) {
        my @values = @$ref;
        tie @$ref, $class;
        @$ref = @values;
    }
    elsif( not $type ) {
        my $value = $ref;
        tie $ref, $class;
        $ref = $value;
    }


    return $ref;

}

sub observer :prototype(&) { MoobX::Observer->new( generator => @_ ) }
sub autorun :prototype(&)  { MoobX::Observer->new( autorun => 1, generator => @_ ) }

1;
