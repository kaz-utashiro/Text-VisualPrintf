[![Build Status](https://travis-ci.com/kaz-utashiro/Text-VisualPrintf.svg?branch=master)](https://travis-ci.com/kaz-utashiro/Text-VisualPrintf) [![MetaCPAN Release](https://badge.fury.io/pl/Text-VisualPrintf.svg)](https://metacpan.org/release/Text-VisualPrintf)
# NAME

Text::VisualPrintf - printf family functions to handle Non-ASCII characters

# SYNOPSIS

    use Text::VisualPrintf;
    Text::VisualPrintf::printf FORMAT, LIST
    Text::VisualPrintf::sprintf FORMAT, LIST

    use Text::VisualPrintf qw(vprintf vsprintf);
    vprintf FORMAT, LIST
    vsprintf FORMAT, LIST

# VERSION

Version 3.01

# DESCRIPTION

Text::VisualPrintf is a almost-printf-compatible library with a
capability of handling multi-byte wide characters properly.

When the given string is truncated by the maximum precision, space
character is padded if the wide character does not fit to the remained
space.  It fails with the target width less than two.

# FUNCTIONS

- printf FORMAT, LIST
- sprintf FORMAT, LIST
- vprintf FORMAT, LIST
- vsprintf FORMAT, LIST

    Use just like perl's _printf_ and _sprintf_ functions
    except that _printf_ does not take FILEHANDLE.

    Take a look at an experimental `Text::VisualPrintf::IO` if you want
    to work with FILEHANDLE and printf.

# IMPLEMENTATION NOTES

Strings in the LIST which contains wide-width character are replaced
before formatting, and recovered after the process.

Unique replacement string contains combinations of control characters
(Control-A to Control-E).  If the FORMAT contains all of these two
bytes combinations, the function behaves just like a standard one.

Because this mechanism expects at least two bytes of string can be
found in the formatted text, it does not work when the string is
truncated to one.

# SEE ALSO

[Text::VisualPrintf](https://metacpan.org/pod/Text::VisualPrintf), [Text::VisualPrintf::IO](https://metacpan.org/pod/Text::VisualPrintf::IO)

[https://github.com/kaz-utashiro/Text-VisualPrintf](https://github.com/kaz-utashiro/Text-VisualPrintf)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright (C) 2011-2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
