#!/usr/bin/perl
use strict;
use warnings;
use utf8;

#use Test::More;
use Data::Dumper;

use EscapeHTML;

my $test = '<a href="example.com/><">example.com</a>\nfoo>bar< hoge&lt;hoge<br>\n\n<script>hoge&hoge</script>\n\n\n<blockquote>\n<i>block<strong>hoge</i></strong>quoted!!';
my $allowed_tags = {
    "a"=> ["href"],
    "p"=> [],
    "blockquote"=> [],
    "i"=> [],
    "strong"=> [],
};

print "\n-----input:-----\n";
print Dumper($allowed_tags);

print "\n-----escaped:-----\n";
my $escaped = EscapeHTML::escape($allowed_tags, $test);
print $escaped . "\n";

print "\n-----quoted:-----\n";
my $quoted = EscapeHTML::blank_line_to_paragraph($escaped);
print $quoted . "\n";

print "\n-----output:-----\n";
#var html = 

#done_testing();
