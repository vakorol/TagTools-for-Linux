# tagtools
#  Makefile.PL
#  use this script to create a makefile for the installation.
#   Author: V.Korol
##################################

use 5.010001;
use ExtUtils::MakeMaker;

### a subroutine to test if a perl module is installed:
sub testMod {
  my $mod = shift;
  eval("use $mod");
  if ($@) {
    return(0);
  } else {
    return(1);
  }
}

### First, check the required modules:
@required_modules = qw(Cwd Encode utf8 Audio::TagLib UI::Dialog::Backend::CDialog);

print "Checking for necessary Perl modules:\n";
foreach $module (@required_modules) {
    if (testMod($module)){
	print " found $module..\n";
    } else {
	die "   Module $module not found, please install!\n";
    }
}


######################
WriteMakefile(
    NAME              => 'TagTools',
    VERSION_FROM      => 'lib/TagTools.pm', # finds $VERSION
    EXE_FILES	      => [ qw(script/tagedit.dialog script/fname2tag script/tag2fname script/tag2fname.dialog
			      script/batchtag.dialog) ],
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/TagTools.pm', # retrieve abstract from module
       AUTHOR         => 'V.Korol <vakorol@mail.ru>') : ()),
);

