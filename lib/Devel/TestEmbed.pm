package Devel::TestEmbed;

$Devel::TestEmbed::VERSION = 1.3;

# Dump just the tests
sub DB::tdump(@) {
  my $outfile = shift || "unnamed_test.t";
  my %test_names = map { $_ => 1 } get_test_names() 
    unless keys %test_names;

  print DB::OUT "Recording tests for this session in $outfile ...";

  unless (open TFH, ">$outfile") {
     print DB::OUT " can't write history: $!\n";
  }
  else {
    my @tests = map { "$_;\n" } 
                grep { is_a_test($_, \%test_names) } @DB::hist;
    print TFH "use Test::More tests=>", int @tests, ";\n";

    my @lines = @DB::hist;
    while (@lines) {
      my $line = shift @lines;
      my $forced_capture = 0;
      # If comments follow the current line, force
      # it to be captured, and save the comments too.
      if (@lines) { 
        while ($lines[0] =~ /^\s*#/) {
          # Yes. Print and discard.
          print TFH $lines[0],"\n";
          $forced_capture = 1;
          shift @lines;
        }
      }
      # skip this one unless we are supposed to keep it
      # or it's a test
      next unless $forced_capture or is_a_test($line, \%test_names); 
      $line = "$line;" unless $line =~ /;$/;
      print TFH $line,"\n";

    }
    close TFH;
    my $s = int @tests == 1 ? "" : "s";
    print DB::OUT " done (", int @tests, " test$s).\n";
  }
}

# Get the names defined in Test::More that are the names of tests
# and save them in a debugger global.
sub get_test_names {
  my @names = keys %Test::More::;
  grep { is_a_sub($_) } @names;
}


# Returns true if this is a sub in Test::More, false otherwise
sub is_a_sub {
  local $_ = shift;
  (!/^_/) and eval "defined &Test::More::$_";
}

# Returns true if this line of history is a Test::More test.
sub is_a_test {
  local $_    = shift;
  my    $map  = shift;
  if (($possible, $paren) = /^\s*(\w+)\(/) {
    return $map->{$possible};
  }
}

1;

__END__

=cut

=head1 NAME

Devel::TestEmbed - extend the debugger with Test::More

=head1 SYNOPSIS

  # We assume that the supplied perldb.sample has been
  # copied to the appropriate place.
  $ perl -demo
  Loading DB routines from perl5db.pl version 1.27
  Editor support available.

  Enter h or `h h' for help, or `man perldebug' for more help.

  main::(-e:1):   mo
  auto(-1)  DB<1> use Test::More qw(no_plan)

    DB<2> use_ok("CGI");

    DB<3> $obj = new CGI;

    DB<4> # Keep 'new CGI' in our test

    DB<5> isa_ok($obj, "CGI")
  ok 2 - The object isa CGI

    DB<6> tdump "our.t"
  Recording tests for this session in our.t ... done (2 tests).

    DB<7> q
  1..2
  $ cat our.t
  use Test::More tests=>2;
  use_ok("CGI");
  # Keep 'new CGI' in our test
  $obj = new CGI;
  isa_ok($obj, "CGI");

=head1 DESCRIPTION

The C<Devel::TestEmbed> module loads C<Test::More> for you, allowing you to
use its functions to test code; you may then save the tests you used in this
debugger session via the C<tdump> function. 

If needed, you may save "setup" code in the test as well by entering a 
comment at the debugger prompt after each line of such code.

The module defines an C<afterinit> and C<watchfunction>; you will need to take this into account if you wish to defined either of these yourself while using this function. See C<perldoc perl5db.pl> for more informaton on these routines.

=head1 BUGS

Package switching is not captured at the moment.

=head1 AUTHOR

Joe McMahon F<E<lt>mcmahon@perl.comE<gt>>.
