use 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'DBI::Simple',
    'VERSION_FROM'	=> 'Simple.pm',
    'PREREQ_PM'		=> {XML::Simple=>2.0},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Simple.pm', # retrieve abstract from module
       AUTHOR     => 'Sean McMurray <span@xolo-web.com>') : ()),
);
