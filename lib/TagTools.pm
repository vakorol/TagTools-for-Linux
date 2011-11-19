#!/usr/bin/perl
#
# TagTools.pm
# audiotagtools for linux - v0.41
# V.Korol (vakorol@mail.ru)
#
# This is a module with useful variables and subroutines shared by audiotagtools scripts.
######################################################################################

package TagTools;

    require Exporter;
    @ISA = qw (Exporter);
    @EXPORT = qw (updateCookieFile readTag initCharset);
    @EXPORT_OK = qw ($VERSION $DEFAULT_CHARSET $COOKIE_FILE);

    use Audio::TagLib;
    use utf8;
    use Encode;

######################################################################################
$VERSION = "0.41";
$DEFAULT_CHARSET = "UTF-8";

$home_dir = `echo ~`;
$home_dir =~ s/\n//;
$COOKIE_FILE = $home_dir."/.tagtools.rc";


######################################################################################
sub updateCookieFile {
    my %new_params, @data, $par, $line;
    undef(@data);

    foreach $par(@_){
	$par=~m/^([\w\_]+)\s*\=(\s*[^\n]*)/;
	$new_params{$1}=$2;
    }

    open cf, "<$COOKIE_FILE";
    while(<cf>){
	$line=$_;
	$line=~m/^\$([\w\_]+)\s*\=/;
	$par=$1;
	(exists($new_params{$par})) ? push(@data,"\$$par=\"$new_params{$par}\";\n") : push(@data,$_);
    }
    close cf;

    open cf, ">$COOKIE_FILE";
    print cf join(/\n/,@data);
}


######################################################################################
sub readTag {
    my $f=$_[0];
    my $charset=$_[1];

    {
	local $SIG{__WARN__}=sub{};   #supress warnings like "Malformed UTF-8 character..."

        ## Read the data as Latin1:
          $title   = $f->tag()->title()  ->toCString();
          $artist  = $f->tag()->artist() ->toCString();
	  $album   = $f->tag()->album()  ->toCString();
          $year    = $f->tag()->year();
          $track   = $f->tag()->track();
          $genre   = $f->tag()->genre()  ->toCString();
          $comment = $f->tag()->comment()->toCString();

        ## Read the data as UTF8:
          $title_8   = $f->tag()->title()  ->toCString(true);
          $artist_8  = $f->tag()->artist() ->toCString(true);
          $album_8   = $f->tag()->album()  ->toCString(true);
          $year_8    = $year;
          $track_8   = $track;
          $genre_8   = $f->tag()->genre()  ->toCString(true);
          $comment_8 = $f->tag()->comment()->toCString(true);
    }

    my @tag = ($title, $artist, $album, $year, $track, $genre, $comment);
    my @tag_8 = ($title_8, $artist_8, $album_8, $year_8, $track_8, $genre_8, $comment_8);

    ## This strange code tries to guess whether the initial data was in UTF8 or not.
    ##  If not - it encodes the data from $charset to utf8.
        my $n=0;
        while($n<=7){
	    my $tag_is_utf8   = utf8::is_utf8($tag[$n]);
    	    my $tag_8_is_utf8 = utf8::is_utf8($tag_8[$n]);

        	if (($tag_is_utf8==1) && ($tag_8_is_utf8==1)) {
        	    if ($charset ne $DEFAULT_CHARSET){
        		utf8::encode($tag[$n]);
        		Encode::from_to($tag[$n],"$charset","$DEFAULT_CHARSET") ;
        	    }
        	} else {
        	    if ($charset ne $DEFAULT_CHARSET){
        		utf8::encode($tag_8[$n]);
        		$tag[$n]=$tag_8[$n];
        	    }
        	}
        	$n++;
        }

    return \@tag;
}


######################################################################################
sub initCharset {
    my $charset = $_[0];
    ## Check if the specified charmap exists
    $charset = $DEFAULT_CHARSET if($charset eq "");
    if ($charset ne $DEFAULT_CHARSET) {
        $enc=find_encoding($charset);
        die "Unknown charset $charset, quitting.\n" unless ref $enc;
    }
    return $charset;
}


######################################################################################
1;


######################################################################################
__END__

=head1 NAME

TagTools

=head1 DESCRIPTION

TagTools is a package of scripts which can be useful to manipulate
audio tags of various audio formats (MP3, OGG, FLAC etc). In fact,
it is an implementation of the Audio::TagLib library 
(http://search.cpan.org/dist/Audio-TagLib/lib/Audio/TagLib.pm),
and provides it with a command-line and dialog-based interface.
TagTools should also work correctly with tags written in different 
codepages (utf8, cp1251 etc).

=head1 CONTENTS

The following scripts are included:

  tag2fname	    - this is a command-line tool to rename a number of
		      files using the information extracted from audio
		      tags in a specified format. Run the command without 
		      options for help.

  tag2fname.dialog  - a dialog-based gui for tag2fname. Run the command without 
		      options for help.

  fname2tag	    - another command-line tool to convert file names
		      into audiotags using a specified format. Run the 
		      command without options for help.

  batchtag.dialog   - a dialog-based tool for batch tag creation. Can
		      update individual tag fields (artist, title, year etc),
		      or runs fname2tag with a specified format. Run the 
		      command without options for help.

  tagedit.dialog    - this script provides a dialog-based tag editing.  Run the 
		      command without options for help.


=head1 AUTHOR

Vasiliy Korol <vakorol@mail.ru>

=head1 COPYRIGHT

This module is free software. You can modify and distribute as part of the TagTools
package.

=cut

