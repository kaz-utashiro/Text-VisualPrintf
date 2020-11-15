package Text::VisualPrintf::Transform;

use v5.14;
use warnings;
use utf8;
use Carp;
use Data::Dumper;
{
    no warnings 'redefine', 'once';
    *Data::Dumper::qquote = sub { qq["${\(shift)}"] };
    $Data::Dumper::Useperl = 1;
    $Data::Dumper::Sortkey = 1;
}

my %char_range = (
    STRAIGHT => [ [0x01=>0x07], [0x10=>0x1f], [0x21=>0x7e], [0x81=>0xfe] ],
    MODERATE => [ [0x21=>0x7e], [0x01=>0x07], [0x10=>0x1f], [0x81=>0xfe] ],
    VISIBLE  => [ [0x21=>0x7e] ],
    );

my %default = (
    test    => undef,
    length  => sub { length $_[0] },
    match   => qr/.+/s,
    except  => '',
    max     => 0,
    visible => 0,
    ordered => 1,
);

sub new {
    my $class = shift;
    my $obj = bless { %default }, $class;
    $obj->configure(@_) if @_;
    $obj;
}

sub configure {
    my $obj = shift;
    while (my($k, $v) = splice @_, 0, 2) {
	if (not exists $default{$k}) {
	    croak "$k: invalid parameter";
	}
	if ($k eq 'test') {
	    $obj->{$k} = do {
		if    (not $v)             { sub { 1 } }
		elsif (ref $v eq 'Regexp') { sub { $_[0] =~ $v } }
		elsif (ref $v eq 'CODE')   { $v }
		else                       { sub { 1 } }
	    };
	} else {
	    $k eq 'length' and ( ref $v eq 'CODE' or die );
	    $obj->{$k} = $v;
	}
    }
    $obj;
}

sub encode {
    my $obj = shift;
    $obj->{replace} = [];
    my $guard = $obj->guard_maker(grep defined, $obj->{except}, @_)
	or return @_;
    my $match = $obj->{match} or die;
    my $test = $obj->{test};
    for my $arg (grep defined, @_) {
	not $test or $test->($arg) or next;
	$arg =~ s{$match}{
	    if (my($replace, $regex, $len) = $guard->(${^MATCH})) {
		push @{$obj->{replace}}, [ $regex, ${^MATCH}, $len ];
		$replace;
	    } else {
		${^MATCH};
	    }
	}pge;
    }
    @_;
}

sub decode {
    my $obj = shift;
    my @replace = @{$obj->{replace}} or return @_;
  ARGS:
    for (@_) {
	for my $i (0 .. $#replace) {
	    my($regex, $orig, $len) = @{$replace[$i]};
	    if (s/$regex/_replace(${^MATCH}, $orig, $len)/pe) {
		if ($obj->{ordered}) {
		    splice @replace, 0, $i + 1;
		} else {
		    splice @replace, $i, 1;
		}
		redo ARGS;
	    }
	}
    }
    @_;
}

sub _replace {
    my($matched, $orig, $len) = @_;
    my $width = length $matched;
    if ($width == $len) {
	$orig;
    } else {
	_trim($orig, $width);
    }
}

sub _trim {
    my($str, $width) = @_;
    use Text::ANSI::Fold;
    state $f = Text::ANSI::Fold->new(padding => 1);
    my($folded, $rest, $w) = $f->fold($str, width => $width);
    if ($w <= $width) {
	$folded;
    } elsif ($width == 1) {
	' '; # wide char not fit to single column
    } else {
	die "Panic"; # should never reach here...
    }
}

sub guard_maker {
    my $obj = shift;
    my $max = $obj->{max};
    local $_ = join '', @_;
    my @a;
    my @range = do {
	map { $_->[0] .. $_->[1] }
	@{ $obj->{range} //= $obj->char_range };
    };
    for my $i (@range) {
	my $c = pack "C", $i;
	push @a, $c unless /\Q$c/;
	last if $max && @a > $max;
    }
    return if @a < 2;
    my $lead = do { local $" = ''; qr/[^\Q@a\E]*+/ };
    my $b = shift @a;
    return sub {
	my $len = $obj->{length}->(+shift =~ s/\X\cH+//gr);
	return if $len < 1;
	my $a = $a[ (state $n)++ % @a ];
	my $bl = $len - 1;
	( $a . ($b x $bl), qr/\G${lead}\K\Q$a$b\E{0,$bl}(?!\Q$b\E)/, $len );
    };
}

sub char_range {
    my $obj = shift;
    my $v = $obj->{visible} // 0;
    if    ($v == 0) { $char_range{STRAIGHT} }
    elsif ($v == 1) { $char_range{MODERATE} }
    elsif ($v == 2) { $char_range{VISIBLE}  }
    else            { die }
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::VisualPrintf::Transform - transform and recover interface for text processing

=head1 SYNOPSIS

    use Text::VisualPrintf::Transform;
    my $xform = Text::VisualPrintf::Transform->new(
        length => \&sub,
        match  => qr/regex/,
        );
    $xform->encode(@args);
    $_ = foo(@args);
    $xform->decode($_);

=head1 DESCRIPTION

This is a general interface to transform text data into desirable
form, and recover the result after the process.

For example, L<Text::Tabs> does not take care of Asian wide characters
to calculate string width.  So next program does not work as we wish.

    use Text::Tabs;
    print expand <>;

In this case, make transform object with B<length> function which can
correctly handle wide character width, and the pattern of string to be
replaced.

    use Text::VisualPrintf::Transform;
    use Text::VisualWidth::PP;
    my $xform = Text::VisualPrintf::Transform->new(
        length => \&Text::VisualWidth::PP::width,
        match  => qr/\P{ASCII}+/,
    );

Then next program encode data, call B<expand>() function, and recover
the result into original text.

    my @lines = <>;
    $xform->encode(@lines);
    my @expanded = expand @lines;
    $xform->decode(@expanded);
    print @expanded;

Be aware that B<encode> and B<decode> method alter the values of given
arguments.  Because they return results as a list too, this can be
done more simply.

    print $xform->decode(expand($xform->encode(<>)));

Next program implements ANSI terminal sequence aware expand command.

    use Text::ANSI::Fold::Util qw(ansi_width);

    my $xform = Text::VisualPrintf::Transform->new(
        length => \&ansi_width,
        match  => qr/[^\t\n]+/,
    );
    while (<>) {
        print $xform->decode(expand($xform->encode($_)));
    }

Calling B<decode> method with many arguments is not a good idea, since
replacement cycle is performed against all entries.  So collect them
into single chunk if possible.

    print $xform->decode(join '', @expanded);

=head1 METHODS

=over 7

=item B<new>

Create transform object.  Takes following parameters.

=over 4

=item B<length> => I<function>

Function to calculate text width.  Default is C<length>.

=item B<match> => I<regex>

Specify text area to be replaced.  Default is C<qr/.+/s>.

=item B<test> => I<regex> or I<sub>

Specify regex or subroutine to test if the argument is to be processed
or not.  Default is B<undef>, so all arguments will be subject to
replace.

=item B<except> => I<string>

Transformation is done by replacing text with different string which
can not be found in all arguments.  This parameter gives additional
string which also to be taken care of.

=item B<visible> => I<number>

=over 4

=item L<0>

With default value 0, this module uses characters in the range:

    [0x01=>0x07], [0x10=>0x1f], [0x21=>0x7e], [0x81=>0xfe]

=item L<1>

Use printable characters first, then use non-printable characters.

    [0x21=>0x7e], [0x01=>0x07], [0x10=>0x1f], [0x81=>0xfe]

=item L<2>

Use only printable characters.

    [0x21=>0x7e]

=back

=begin comment

=item B<ordered>

...

=end comment

=back

=item B<encode>

=item B<decode>

Encode/Decode arguments and return them.  Given arguments will be
altered.

=back

=head1 LIMITATION

All arguments given to B<encode> method have to appear in the same
order in the pre-decode string.  Each argument can be shorter than the
original, or it can even disappear.

If an argument is trimmed down to single byte in a result, and it have
to be recovered to wide character, it is replaced by single space.

Replacement string is made of characters those can not be found in all
arguments.  So if they contains all characters in the given range,
B<encode> stop to work.  It requires at least two.

Minimum two characters are enough to produce correct result if all
arguments will appear in the same order.  However, if even single item
is missing, it won't work correctly.  Using three characters, one
continuous missing is allowed.  Less characters, more confusion.

=head1 SEE ALSO

=over 4

=item L<Text::VisualPrintf>, L<https://github.com/kaz-utashiro/Text-VisualPrintf>

This module is originally implemented as a part of
L<Text::VisualPrintf> module.

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#  LocalWords:  ansi xform regex undef
