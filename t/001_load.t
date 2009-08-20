# -*- perl -*-

# t/001_load.t - check module loading

use Test::More tests => 8;

BEGIN { use_ok('Devel::TestEmbed'); }

# See if the functions we expect are defined.
can_ok("DB", "tdump");
can_ok("Devel::TestEmbed", "is_a_test");
can_ok("Devel::TestEmbed", "is_a_sub");
can_ok("Devel::TestEmbed", "get_test_names");

# Fake loading .perldb and check to see the functions are there
# Note that since this isn't the debugger loading these functions,
# they'll end up in main, not DB.
push @INC, "scripts";
require_ok(qq("perldb.sample"));
can_ok("main", "afterinit");
can_ok("main", "watchfunction");
