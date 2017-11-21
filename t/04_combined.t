use strict;
use warnings;
use utf8;
use open ':std', ':encoding(utf8)';
use Text::VisualPrintf 'vsprintf';

sub kana {
    my $X_KANA = shift;
    map  { @$_ }
    grep { defined $_->[1] }
    map  { [ $_->[0], eval "\"$_->[1]\"" ] }	# "\N{NAME}"
    map  { [ $_->[0], "\\N{$_->[1]}" ] }	# \N{NAME}
    map  {					# UNICODE NAME
	( [ $_,    "$X_KANA LETTER $_" ],
	  [ "x$_", "$X_KANA LETTER SMALL $_" ] )
    }
    map  {					# KA KI KU KE KO SA ...
	my $c = $_;
	map { "$c$_" } qw(A I U E O);
    }
    'KSTNHMYRW GZDBP' =~ /\A|\w/g;
}
my %k = kana "KATAKANA";
my %h = kana "HIRAGANA";
my %m = (
    'CT' => "\N{COMBINING KATAKANA-HIRAGANA VOICED SOUND MARK}",
    'CM' => "\N{COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK}",
    'T'  => "\N{KATAKANA-HIRAGANA VOICED SOUND MARK}",
    'M'  => "\N{KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK}",
    );

use Test::More tests => 3;

 NORMAL:
{
     is( vsprintf( "%5s", 'ぱ'), '   ぱ', 'ぱ' );
}

 WORKING:
{
    local $TODO = "Japanese combining character.";

    is( vsprintf( "%5s", "$h{HA}$m{CM}" ),
	"   $h{HA}$m{CM}",
	'は + ゜');

}

 TODO:
{
    local $TODO = "Stand-alone non-spacing character.";
    # Causes run-time error, because the width is zero.
    is( vsprintf( "は%-5s", "$m{CM}" ),
	"は$m{CM}     ",
	'は + ゜' );
}

done_testing;