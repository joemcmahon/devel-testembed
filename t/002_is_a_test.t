use Test::More tests=>2;

use Devel::TestEmbed;
my $map = {'ok' => 1};

ok(Devel::TestEmbed::_is_a_test("ok()", $map), "ok found as expected");
ok(!Devel::TestEmbed::_is_a_test("bad()", $map), "bad not found as expected");
