package MoobX::Hash::Observable;
# ABSTRACT: Observable role for MobX hashes

=head1 DESCRIPTION

Role applied to L<MoobX::hash> objects to make them observables.

Used internally by L<MoobX>.

=cut

use Moose::Role;

use experimental 'postderef', 'signatures';

use Scalar::Util 'refaddr';

before [ qw/ FETCH FIRSTKEY NEXTKEY EXISTS /] => sub {
    my $self = shift;
    push @MoobX::DEPENDENCIES, $self if $MoobX::WATCHING;
};


after [ qw/ STORE CLEAR DELETE /] => sub {
    my $self = shift;
    for my $i ( values $self->value->%* ) {
        next if tied $i;
        next unless ref $i;
        my $type = ref  $i;
        if( $type eq 'ARRAY' ) {
            MoobX::observable( @$i );
        }
        elsif( $type eq 'HASH' ) {
            MoobX::observable( %$i );
        }
    }
    MoobX::observable_modified( $self );
};

1;
