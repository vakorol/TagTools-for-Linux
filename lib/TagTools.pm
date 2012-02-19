#!/usr/bin/perl
#
# TagTools.pm
# audiotagtools for linux - v0.43a
# V.Korol (vakorol@mail.ru)
#
# This is a module with useful variables and subroutines shared by audiotagtools scripts.
######################################################################################

package TagTools;

    require Exporter;
    @ISA = qw (Exporter);
    @EXPORT = qw (updateCookieFile readTag initCharset printLog getFileInfo removeTrailingSpaces);
    @EXPORT_OK = qw ($VERSION $DEFAULT_CHARSET $COOKIE_FILE $DEBUG_ON $DEBUG_FILE);

    use utf8;
    use Encode;
    use Encode::Byte;
    use Cwd;

    use Audio::TagLib;

######################################################################################
$VERSION = "0.43a";
$DEFAULT_CHARSET = "UTF-8";

$home_dir = `echo ~`;
$home_dir =~ s/\n//;
$COOKIE_FILE = $home_dir."/.tagtools.rc";

$DEBUG_ON = 0;             # 0 - off;  1 - turn on debug messages to $DEBUG_FILE
$DEBUG_FILE = $home_dir."/tagtools.log";
#$DEBUG_FILE = ($DEBUG_ON) ? $home_dir."/tagtools.log" : "/dev/null";


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
	if(exists($new_params{$par})){
	    push(@data,"\$$par=\"$new_params{$par}\";\n");
	    delete $new_params{$par};
	} else {
	    push(@data,$_);
	}
    }
    close cf;

    open cf, ">$COOKIE_FILE";
     print cf join(/\n/,@data);
     foreach $par(keys(%new_params)){
      print cf "\$$par=\"$new_params{$par}\";\n";
     }
    close cf;
}


######################################################################################
sub readTag {
    my $f=$_[0];
    my $charset=$_[1];

    $charset = initCharset($charset);

    {
        #supress warnings like "Malformed UTF-8 character...":
          local $SIG{__WARN__} = ($DEBUG_ON) ? 
                sub{warn print (localtime()." -- ".$0." in call to ".(caller(0))[3])." -- ".@_} : 
                 sub{};

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
        		utf8::encode($tag[$n]);
        	    if ($charset ne $DEFAULT_CHARSET){
        		Encode::from_to($tag[$n],"$charset","$DEFAULT_CHARSET") ;
        	    }
        	} else {
        		utf8::encode($tag_8[$n]);
        	    if ($charset ne $DEFAULT_CHARSET){
        		$tag[$n]=$tag_8[$n];
        	    }
        	}

	    ## Remove non-printable characters:
	    $tag[$n]=~s/[\f\n\r\t]/\s/g;
	    ## Substitute semicolon with colon (UI::CDialog can't show the former):
	    $tag[$n]=~s/\"/\'/g;

    	    $n++;
        }
    return \@tag;
}


######################################################################################
sub initCharset {
    my $charset = $_[0];
    ## Check if the specified charmap exists
    $charset = $DEFAULT_CHARSET if(($charset eq "") || !defined($charset));
    if ($charset ne $DEFAULT_CHARSET) {
        $enc=find_encoding($charset);
        die "Unknown charset $charset, quitting.\n" unless ref $enc;
    }
    return $charset;
}


######################################################################################
sub printLog {
    my $log_info = $_[0];
     open (DF, ">>$DEBUG_FILE") or return 0;
      print DF localtime()." -- ".$log_info."\n";
     close (DF);
    return 1;
}


######################################################################################
sub getFileInfo {
    my $f = $_[0];

    ## get tech info (length and bitrate):
    my $audio_bitrate = $f->audioProperties()->bitrate();
    my $audio_sample  = $f->audioProperties()->sampleRate();
     my @full_length = gmtime( $f->audioProperties()->length() );
     my $audio_length  = sprintf ("%02d:%02d", $full_length[1], $full_length[0]);

    ## get workdir and short filename
    my $cwd = getcwd();
    my $short_filename = $f->file()->name();
    $short_filename =~ s/^.+?\/([^\/]+)$/$1/;  #extract only the filename from the full path

    my @fileInfo = ($audio_length, $audio_bitrate, $audio_sample, $cwd, $short_filename);
    return \@fileInfo;
}


######################################################################################
sub removeTrailingSpaces {
    my @data = @{$_[0]};  # the 1st arg is a ref to an array

    # correct the spaces bug from CDialog - remove traling spaces:
    foreach $item(@data){
      $item =~ s/\s+$//;
    }
    
    return \@data;
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
