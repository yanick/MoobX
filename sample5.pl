use 5.20.0;

use MoobX;

use List::AllUtils qw/ first /;

observable my @foo;
@foo = ( 1..10 );

my $value = observer { first { $_ > 2 } @foo };

say $value;

use DDP;
p $value->dependencies;


