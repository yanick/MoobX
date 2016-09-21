use 5.20.0;

use MoobX;

observable my $first_name;
observable my $last_name;
observable my $title;

my $address = observer {
    join ' ', $title || $first_name, $last_name;
};

observable my @things;

print $address;

$first_name = "Yanick";
$last_name = "Champoux";

say $address;

use Data::Printer;
p $address->dependencies;

$title = 'Dread Lord';

say $address;

p $address->dependencies;
