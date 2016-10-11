#!/usr/bin/perl

use EscapeHTML qw(blank_line_to_paragraph escape_html);

use Data::Dumper;

sub main {
    my $test = '<a href="example.com/><">example.com</a>\nfoo>bar< hoge&lt;hoge<br>\n\n<script>hoge&hoge</script>\n<blockquote><i>block<strong>hoge</i></strong>quoted!!';

    my $allowed_tags = {
                         "a" => ["href"],
                         "p" =>  [],
                         "blockquote" => [],
                         "i" => [],
                         "strong" => [],
                        };

    print "\n-----input:-----\n";
    print Dumper($test);

    print "\n-----quoted:-----\n";
    my $escaped = escape_html($allowed_tags, $test);
    print $escaped;
    #print "\n\n";
    #my $quoted = blank_line_to_paragraph($escaped);
    #print $quoted;

#  console.log("\n-----output:-----");
#  const html = jq.parseHTML(quoted, null);
#  html.forEach(i => {
#    i.normalize();
#    console.log(i.outerHTML);
#  });
}

main();
