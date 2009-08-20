use Test::More tests=>53;
use Devel::TestEmbed;

tie *DB::OUT, 'Capture';
open (DB::OUT, "dummy - not actually opened");
$contents = tied *DB::OUT;

sub erase {
  @DB::hist = ();
  unlink "t/check.output" or die "Can't unlink check.output: $!\n"
    if -e "t/check.output";
  close DB::OUT;
  open (DB::OUT, "reopen for capture");
}

sub slurp {
  my $file = (shift || "t/check.output");
  open SLURP, $file  or die "Can't read check.output: $!\n";
  my @file = <SLURP>;
  close SLURP;
  @file;
}

# Clean up to start out.
erase;

# tdump() expects @DB::hist to be around; we'l define it and fill it up
# with various possibilities.


# Test 1: empty.
DB::tdump("t/check.output");
ok($contents->contents, "got a message");
is($$contents, qq[Recording tests for this session in t/check.output ... done (0 tests).\n],
     "expected message ok");
@lines = slurp();
ok(int @lines, "Something there");
is(int @lines, 1, "one line as expected");
is($lines[0], "use Test::More tests=>0;\n", "the output expected");
erase;

# Test 2: some input, but none of it tests.
@DB::hist = (
              '?',
              'definitely not a test',
              'bogus(1)',
              'zorch'
            );
DB::tdump("t/check.output");
@lines = slurp();
ok(int @lines, "Something there");
is(int @lines, 1, "one line as expected");
is($lines[0], "use Test::More tests=>0;\n", "the output expected");
ok($$contents, "got a message");
is($$contents, qq[Recording tests for this session in t/check.output ... done (0 tests).\n],
     "expected message ok");
erase;

# Test 3: Can't touch this.
SKIP:{
  skip "Can't do unwritable file test as root", 2 unless $> != 0;
  open(JUNK,">t/nowrite.file");
  close JUNK;
  chmod 0000, "t/nowrite.file";
  DB::tdump("t/nowrite.file");
  ok($$contents, "got a message");
  like($$contents, qr/can't write history:/, "expected error");
  chmod 0700, "t/nowrite.file";
  unlink "t/nowrite.file";
erase;
}

# Test 4: one test, no setup.
@ DB::hist = (
               '?',
               '$x="this is setup"',
               '$y="no comment to trap it"',
               'is(1,1)',
               'c'
             );
DB::tdump("t/check.output");
@lines = slurp();
ok(int @lines, "Something there");
is(int @lines, 2, "two lines as expected");
is_deeply(\@lines, [ qq(use Test::More tests=>1;\n),
                     qq(is(1,1);\n) ], "the output expected");
ok($$contents, "got a message");
is($$contents, qq[Recording tests for this session in t/check.output ... done (1 test).\n],
     "expected message ok");
erase;

# Test 5: two tests, no setup.
@ DB::hist = (
               '?',
               '$x="this is setup"',
               '$y="no comment to trap it"',
               'is(1,1)',
               'c',
               'isnt(2,1)',
             );
DB::tdump("t/check.output");
@lines = slurp();
ok(int @lines, "Something there");
is(int @lines, 3, "three lines as expected");
is_deeply(\@lines, [ qq(use Test::More tests=>2;\n),
                     qq(is(1,1);\n),
                     qq(isnt(2,1);\n) ], "the output expected");
ok($$contents, "got a message");
is($$contents, qq[Recording tests for this session in t/check.output ... done (2 tests).\n],
     "expected message ok");
erase;

# Test 6: no tests, setup with one comment.
@ DB::hist = (
               '?',
               '$x="this is not trapped"',
               '$y="this has a comment to trap it"',
               '# $y should be captured here',
               'c',
             );
DB::tdump("t/check.output");
@lines = slurp();
ok(int @lines, "Something there");
is(int @lines, 3, "three lines as expected");
is_deeply(\@lines, [ qq(use Test::More tests=>0;\n),
                     q(# $y should be captured here)."\n",
                     q($y="this has a comment to trap it";)."\n" ], 
          "the output expected");
ok($$contents, "got a message");
is($$contents, qq[Recording tests for this session in t/check.output ... done (0 tests).\n],
     "expected message ok");
erase;

# Test 7: no test, setup with two comments.
@ DB::hist = (
               '?',
               '$x="this is not trapped"',
               '$y="this has a comment to trap it"',
               '# $y should be captured here',
               '# this comment comes second',
               'c',
             );
DB::tdump("t/check.output");
@lines = slurp();
ok(int @lines, "Something there");
is(int @lines, 4, "four lines as expected");
is_deeply(\@lines, [ qq(use Test::More tests=>0;\n),
                     q(# $y should be captured here)."\n",
                     q(# this comment comes second)."\n",
                     q($y="this has a comment to trap it";)."\n" ], 
          "the output expected");
ok($$contents, "got a message");
is($$contents, qq[Recording tests for this session in t/check.output ... done (0 tests).\n],
     "expected message ok");
erase;

# Test 7: one test before, setup with two comments.
@ DB::hist = (
               '?',
               '$x="this is not trapped"',
               'is(1,1)',
               '$y="this has a comment to trap it"',
               '# $y should be captured here',
               '# this comment comes second',
               'c',
             );
DB::tdump("t/check.output");
@lines = slurp();
ok(int @lines, "Something there");
is(int @lines, 5, "five lines as expected");
is_deeply(\@lines, [ qq(use Test::More tests=>1;\n),
                     qq[is(1,1);\n],
                     q(# $y should be captured here)."\n",
                     q(# this comment comes second)."\n",
                     q($y="this has a comment to trap it";)."\n" ], 
          "the output expected");
ok($$contents, "got a message");
is($$contents, qq[Recording tests for this session in t/check.output ... done (1 test).\n],
     "expected message ok");
erase;

# Test 8: one test after, setup with two comments.
@ DB::hist = (
               '?',
               '$x="this is not trapped"',
               '$y="this has a comment to trap it"',
               '# $y should be captured here',
               '# this comment comes second',
               'is(1,1)',
               'c',
             );
DB::tdump("t/check.output");
@lines = slurp();
ok(int @lines, "Something there");
is(int @lines, 5, "five lines as expected");
is_deeply(\@lines, [ qq(use Test::More tests=>1;\n),
                     q(# $y should be captured here)."\n",
                     q(# this comment comes second)."\n",
                     q($y="this has a comment to trap it";)."\n",
                     qq[is(1,1);\n] ], 
          "the output expected");
ok($$contents, "got a message");
is($$contents, qq[Recording tests for this session in t/check.output ... done (1 test).\n],
     "expected message ok");
erase;

# Test 9: one test before and one after, setup with two comments.
@ DB::hist = (
               '?',
               'is(0,0)',
               '$x="this is not trapped"',
               '$y="this has a comment to trap it"',
               '# $y should be captured here',
               '# this comment comes second',
               'is(1,1)',
               'c',
             );
DB::tdump("t/check.output");
@lines = slurp();
ok(int @lines, "Something there");
is(int @lines, 6, "six lines as expected");
is_deeply(\@lines, [ qq(use Test::More tests=>2;\n),
                     qq[is(0,0);\n],
                     q(# $y should be captured here)."\n",
                     q(# this comment comes second)."\n",
                     q($y="this has a comment to trap it";)."\n",
                     qq[is(1,1);\n] ], 
          "the output expected");
ok($$contents, "got a message");
is($$contents, qq[Recording tests for this session in t/check.output ... done (2 tests).\n],
     "expected message ok");
erase;

# Test 10 - no output file specified
unlink("unnamed_test.t");
@ DB::hist = (
               '?',
               'is(0,0)',
               '$x="this is not trapped"',
               '$y="this has a comment to trap it"',
               '# $y should be captured here',
               '# this comment comes second',
               'is(1,1)',
               'c',
             );
DB::tdump();
ok(-e "unnamed_test.t", "default file now exists");
@lines = slurp("unnamed_test.t");
ok(int @lines, "Something there");
is(int @lines, 6, "six lines as expected");
is_deeply(\@lines, [ qq(use Test::More tests=>2;\n),
                     qq[is(0,0);\n],
                     q(# $y should be captured here)."\n",
                     q(# this comment comes second)."\n",
                     q($y="this has a comment to trap it";)."\n",
                     qq[is(1,1);\n] ], 
          "the output expected");
ok($$contents, "got a message");
is($$contents, qq[Recording tests for this session in unnamed_test.t ... done (2 tests).\n],
     "expected message ok");
unlink("unnamed_test.t");
erase;
# Clean up on termination.
END {
  erase();
}

package Capture;
use Tie::Handle;
use Test::More;
 
sub TIEHANDLE {
  my $class = shift;
  my $string = "";
  my $self = \$string;
  bless $self, $class;
}

sub OPEN {
  my $self = shift;
  $$self = "";
}

sub PRINT {
  my $self = shift;
  $$self .= join("", @_);
}  

sub FILENO {
 "Not really a file";
}

sub CLOSE { 
}

sub contents { ${shift()} }
