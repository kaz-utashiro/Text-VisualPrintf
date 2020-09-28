use strict;
use warnings;
use utf8;
use open IO => ':utf8', ':std';
use Text::VisualPrintf;

use Test::More;

is( Text::VisualPrintf::sprintf( "%5s", '%s'),     '   %s', '%s in %s' );
is( Text::VisualPrintf::sprintf( "%5s", '$^X'),    '  $^X', 'VAR' );
is( Text::VisualPrintf::sprintf( "%5s", '@ARGV'),  '@ARGV', 'ARRAY' );

is( Text::VisualPrintf::sprintf( "(%s, %s, %s)",
				 "\001\001", "日本語", "\001\002" ),
    "(\001\001, 日本語, \001\002)", 'ARRAY' );

is( Text::VisualPrintf::sprintf( "(%s, %s, %s)",
				 "日本語", "\001\001", "\001\002" ),
    "(日本語, \001\001, \001\002)", 'ARRAY' );

is( Text::VisualPrintf::sprintf( "\001\001(%s, %s, %s)",
				 "壱", "日本語", "\001\002" ),
    "\001\001(壱, 日本語, \001\002)", 'ARRAY' );

sub ctrls {
    my($i, $j) = @_;
    my @seq;
    for my $i (1 .. $i) {
	for my $j (1 .. $j//$i) {
	    push @seq, pack "CC", $i, $j;
	}
    }
    local $" = '';
    wantarray ? @seq : "@seq";
};

my $longseq = ctrls(5, 3);
is( Text::VisualPrintf::sprintf("$longseq(%5s)", "壱"),
    "$longseq(   壱)",
    'Long binary format.');

# TODO:
{
#    local $TODO = "Outlimit";
    my $allseq = ctrls(5, 5);
    is( Text::VisualPrintf::sprintf("$allseq(%5s)", "壱"),
	"$allseq(   壱)",
	'5x5 binary pattern format.');
}

for my $i (1..253) {
    my $allseq = join '', (map { pack("C", $_) } 1 .. $i);
    $allseq =~ s///g;
    is( Text::VisualPrintf::sprintf($allseq =~ s/%/%%/gr . "(%5s)", "壱"),
	"$allseq(   壱)",
	"Many ASCII format ($i)");
}

 TODO:
for my $i (254..255) {
    local $TODO = "Too many ASCII ($i)";
    my $allseq = join '', (map { pack("C", $_) } 1 .. $i);
    is( Text::VisualPrintf::sprintf($allseq =~ s/%/%%/gr . "(%5s)", "壱"),
	"$allseq(   壱)",
	"Too many ASCII format ($i)");
}

# TODO:
{
#    local $TODO = "Outlimit param";
    my @allseq = ctrls(5, 5);
    my $format = "%s" x @allseq . "(%5s)";
    my $expect = join '', @allseq, "(   壱)";
    is( Text::VisualPrintf::sprintf($format, @allseq, "壱"),
	$expect,
	'All binary pattern paramater.');
}

{
    is( Text::VisualPrintf::sprintf("%.4s", "112233"),
	"1122",
	'truncation. (ASCII)');
}

{
    is( Text::VisualPrintf::sprintf("%.3s", "ｱｲｳｴｵ"),
	"ｱｲｳ",
	'truncation. (Half-width KANA)');
}

{
    is( Text::VisualPrintf::sprintf("%.4s", "一二三"),
	"一二",
	'truncation. (Kanji)');
}

{
    is( Text::VisualPrintf::sprintf("%.3s", "一二三"),
	"一 ",
	'truncation. (Kanji with padding)');
}

{
    is( Text::VisualPrintf::sprintf("%.3s", "一23"),
	"一2",
	'truncation. (Kanji + ASCII)');
}

# TODO:
{
#    local $TODO = "Truncation to 1 (Half-width KANA)";
    is( Text::VisualPrintf::sprintf("%.1s", "ｱｲｳ"),
	"ｱ",
	'truncation. (1 column)');
}

{
    is( Text::VisualPrintf::sprintf("%.2s", "ｱイウ"),
	"ｱ ",
	'truncation. (Half-width with padding)');
}

# TODO:
{
#    local $TODO = "Truncation to 1";
    # This behavior seems to be consistent.
    is( Text::VisualPrintf::sprintf("%.1s", "一二三"),
	" ",
	'truncation. (1 column)');
}

done_testing;
