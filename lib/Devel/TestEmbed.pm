package Devel::TestEmbed;

$Devel::TestEmbed::VERSION = 1.4;

# Dump just the tests
sub DB::tdump(@) {
  my $outfile = shift || "unnamed_test.t";
  my %test_names = map { $_ => 1 } _get_test_names() 
    unless keys %test_names;

  print DB::OUT "Recording tests for this session in $outfile ...";

  unless (open TFH, ">$outfile") {
     print DB::OUT " can't write history: $!\n";
  }
  else {
    my @tests = map { "$_;\n" } 
                grep { _is_a_test($_, \%test_names) } @DB::hist;
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
      next unless $forced_capture or _is_a_test($line, \%test_names); 
      $line = "$line;" unless $line =~ /;$/;
      print TFH $line,"\n";

    }
    close TFH;
    my $s = int @tests == 1 ? "" : "s";
    print DB::OUT " done (", int @tests, " test$s).\n";
  }
}

# Scans the Test::More namespace and returns a list of anything that 
# seems to be a sub name.
sub _get_test_names {
  my @names = keys %Test::More::;
  grep { _is_a_sub($_) } @names;
}

# Returns true if this is a sub in Test::More, false otherwise.
# A name is considered to be a sub if a subroutine reference
# to it is defined, and if the name does not start with an 
# underscore.
sub _is_a_sub {
  local $_ = shift;
  (!/^_/) and eval "defined &Test::More::$_";
}

# Returns true if this line of history is a Test::More test.
sub _is_a_test {
  local $_    = shift;
  my    $map  = shift;
  if (($possible, $paren) = /^\s*(\w+)\(/) {
    return $map->{$possible};
  }
}

1;

__END__

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

The module defines an C<afterinit> and C<watchfunction>; you will need to take this into account 
if you wish to defined either of these yourself while using this function. See C<perldoc perl5db.pl> 
for more informaton on these routines.

=head1 THE HACK

This solution to extending the debugger is a hack using the debugger's default behaviors in 
conjunction with some non-standard uses of the debugger's standard interfaces.

=head2 afterinit()

The debugger allows you to define an C<afterinit> function in C<.perldb> (the debugger's
equivalent to a C<.rc> or <init> file). C<afterinit> gets called, not surprisingly, after
the debugger has finished its initialization and before it prompts the user for the first
command.

This allows us to do a number of things on behalf of the user:

=over 4

=item * Load C<Test::More> into the program's namespace.

=item * Load this module into the debugger's namespace.

=item * Turn on the magical flag that tells the debugger to run a C<watchfunction>.

=back

=head2 watchfunction()

C<watchfunction()> gets called just before the command loop starts. We use it to
install the C<tdump()> subroutine into the current namespace (whatever namespace
that happens to be).

=head2 Debugger's default behavior

When the debugger gets a command line it doesn't understand, it assumes that it
mus be a Perl expression, so it goes ahead and evaluates this expression in the
context of the I<program being debugged>. This is what allows you to just say
C<print $blah> and have it actually be C<$blah> from your program, not the 
debugger.

=head2 How it all comes together

First the debugger gets up and running.

=over 4 

=item 1. Perl starts and sees C<-d> on the command line. It loades the debugger.

=item 2. The debugger initializes, looks for C<.perldb> and executes it.

=item 3. C<.perldb> defines C<afterinit> and C<watchfunction>. 

=item 4. Perl calls C<afterinit>.

=item 5. C<afterinit> loads C<Devel::TestEmbed> and stacks C<use Test::More plan=&lt;no_plan> on the debugger's typeahead stack, C<@DB::typeahead>.

=item 6. The debugger calls C<watchfunction>, which installs C<tdump> into the current namespace.

=item 7. The debugger starts reading commands, and pulls the C<use> off the typeahead stack and executes it.

=item 8. The debugger finally prompts the user for input.

=back

Now everything's in place. If we enter a C<Test::More> sub:

=over 4

=item 1. The debugger decides it doesn't understand the line.

=item 2. The debugger evaluates the line in the current namespace.

=item 3. The proper C<Test::More> sub is called, and the test runs.

=item 4. The debugger saves the line on C<@DB::hist> (its command history).

=back

If we enter C<tdump something>:

=over 4

=item 1. The debugger decides it doesn't understand this either.

=item 2. The debugger evaluates the line in the current namespace. Since C<tdump> has been imported there. it runs.

=item 3. C<tdump> ferrets through C<@DB::hist> and extracts anything which matches its list of "subs found in C<Test::More> that are tests".

=item 4. C<tdump> writes the file and prints a "hi, I saved your tests" message.

=back

=head1 SUBROUTINES

=head2 tdump

This is the actual command code that searches through the 
debugger's history and writes the test file. It takes an
optional argument of the string to be used as the file name.

=head1 BUGS

The "command" doesn't get to parse the debugger command line itself, so if you say 
something like C<tdump foo.t> without quotes around the C<foo.t>, you'll find that 
Perl has evaluated this as an expression and merrily written your test to the file
C<foot>.

Package switching in the debugger is not captured.

Tests which have been dumped once get dumped again if you use C<tdump> multiple times.

Running the debugger with this enabled can C<vastly> slow down the execution of your program,
because C<watchfunction> is getting called every time a line of your program executes.

The C<tdump> routine is forcibly imported into every package when execution goes to that
package. If that package has its own C<tdump> routine, chaos is likely to result.

You should be using C<Devel::Command> instead of this module if you want a nice clean
implementation of debugger command extensions.

=head1 SEE ALSO

C<Devel::Command> for a considerably better way to do this.
C<perl5db.pl> for a detailed description of how C<afterinit> and C<watchfunction> work.

=head1 AUTHOR

Joe McMahon F<E<lt>mcmahon@cpan.org<gt>>.
