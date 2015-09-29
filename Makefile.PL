use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	   => 'swatchdog',
    'VERSION_FROM' => 'swatchdog',
    'EXE_FILES'    => [ 'swatchdog' ],
    'PREREQ_PM' => {
                     'Time::HiRes' => '1.12',
                     'Date::Calc' => '0',
                     'Date::Format' => '0',
                     'Date::Manip' => '0',
                     'File::Tail' => '0',
                     'Term::ANSIColor' => '0',
                   },
    'dist'         => { 
                        'SUFFIX'       => ".gz",
			'DIST_DEFAULT' => 'all tardist',
			'COMPRESS'     => "gzip -9f" 
                      },
    'realclean'    => { 'FILES' => '' },
    'clean'        => { 'FILES' => '' },
);
