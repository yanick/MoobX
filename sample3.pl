use 5.20.0;

use DDP;

use MoobX;

observable my @things;

my $list = observer { join ' ', map @$_, @things };

say $list;

p $list->dependencies;

@things = ( [1],[2],[3]);

say $list;

p $list->dependencies;

push @things, [4];
say $list;

$things[0][0] = 5;
say $list;
