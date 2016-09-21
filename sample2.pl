use 5.20.0;

use Scalar::Util 'reftype';




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





observable my $first_name;
observable my $last_name;
observable my $title;

my $address = observer {
    join ' ', $title || $first_name, $last_name;
};

observable my @things;


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
