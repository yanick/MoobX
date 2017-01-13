package MoobX::Attributes;
#ABSTRACT: Attributes to annotate variables as MoobX observables

=head1 SYNOPSIS

    use MoobX;

    my $foo :Observable;

=head1 DESCRIPTION

Used internally by L<MoobX>.

=cut


use 5.20.0;

use MoobX '!:attributes';

use Attribute::Handlers;

no warnings 'redefine';

sub Observable :ATTR(SCALAR) {
    my ($package, $symbol, $referent, $attr, $data) = @_;

    MoobX::observable_ref($referent);
}

sub Observable :ATTR(ARRAY) {
    my ($package, $symbol, $referent, $attr, $data) = @_;

    MoobX::observable_ref($referent);
}

sub Observable :ATTR(HASH) {
    my ($package, $symbol, $referent, $attr, $data) = @_;

    MoobX::observable_ref($referent);
}

1;
