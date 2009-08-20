use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Devel::TestEmbed',
    VERSION_FROM => 'lib/Devel/TestEmbed.pm', # finds $VERSION
    AUTHOR       => 'Joe McMahon (mcmahon@perl.com)',
    ABSTRACT     => 'embedded test support in the debugger',
    PREREQ_PM    => {
                     'Test::More' => 0,
                    },
);
