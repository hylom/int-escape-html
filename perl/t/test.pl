#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Test::More;
use Data::Dumper;

BEGIN {
    push @INC, ".";
}

sub test_output {
    my ($test, $allowed_tags) = @_;

    print "\n-----input:-----\n";
    print $test;

    print "\n-----escaped:-----\n";
    my $escaped = EscapeHTML::escape($allowed_tags, $test);
    print $escaped . "\n";

    print "\n-----paragraphed:-----\n";
    my $quoted = EscapeHTML::blank_line_to_paragraph($escaped);
    print $quoted . "\n";

    print "\n-----output:-----\n";
}

use EscapeHTML;

my $allowed_tags = { "a"=> ["href"],
                     "p"=> [],
                     "blockquote"=> ["title", "cite"],
                     "i"=> [],
                     "strong"=> [],
                     "br" => [],
                   };

my $test = <<EOL;
<a name>hoge</a><a href="example.com/><">example.com</a>
foo>bar< hoge&lt;hoge<br>

<script>hoge&hoge</script>


<blockquote
>
<i>block<strong>hoge</i></strong>quoted!!;
EOL

my $expect = <<EOL;
&lt;a name&gt;hoge</a><a href="example.com/><">example.com</a>
foo&gt;bar&lt; hoge&lt;hoge<br>

&lt;script&gt;hoge&hoge&lt;/script&gt;


<blockquote
>
<i>block<strong>hoge</i></strong>quoted!!;
EOL

is(EscapeHTML::escape($allowed_tags, $test), $expect, "test01");
test_output($test, $allowed_tags);

done_testing;
