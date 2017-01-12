use 5.20.0;

use MoobX;

use List::AllUtils qw/ first /;

observable my @foo;
@foo = ( 1..10 );

my $value = observer { first { $_ > 2 } @foo };

autorun {
    say "foo changed!";
    say join ' ', @foo;
};

say $value;

use DDP;
p $value->dependencies;

push @foo, 12;

