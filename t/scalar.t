use Test::More;

use 5.20.0;

use Data::Printer;
use MoobX;

observable my $first_name;
observable my $last_name;
observable my $title;

my $address = observer {
    join ' ', $title || $first_name, $last_name;
};

is $address, ' ', "begin empty";

( $first_name, $last_name ) = qw/ Yanick Champoux /;

is $address => 'Yanick Champoux';

$title = 'Dread Lord';

is $address => 'Dread Lord Champoux';

done_testing;
