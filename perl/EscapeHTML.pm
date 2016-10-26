package EscapeHTML;
use Exporter 'import';
our @EXPORT_OK = qw(blank_line_to_paragraph escape_html);
our @EXPORT = qw(blank_line_to_paragraph escape_html);

use strict;
use warnings;
use utf8;

use Data::Dumper;

sub blank_line_to_paragraph {
    my $text = shift;
    my @lines = split /(\r\n|\n|\r)/, $text;
    my $blank = '^\s*$';
    my $results = ["<p>"];
    my $cont = 0;

    for my $l (@lines) {
        if ($l =~ /$blank/) {
            if (!$cont) {
                $cont = 1;
                push @$results, "</p><p>";
            }
        } else {
            push @$results, $l;
            $cont = 0;
        }
    }
    push @$results, "</p>";
    return join("\n", @$results);
}

sub trim {
    my $t = shift;
    $t =~ s/\A\s*(.*)\s*\z/$1/;
    return $t;
}

sub escape_tag {
    my ($allowed_tags, $tag) = @_;
    if (%$allowed_tags) {
        return _escape($tag);
    }
    my $rex = '\A<(.*)>\z';
    $tag =~ m/$rex/;
    my $m = $1;

    if (!$m) {
        return _escape($tag);
    }
    my $body = trim($m);
    if (length $body == 0) {
        return _escape($tag);
    }

    # check if end tag?
    if ((substr $body, 0, 1) eq '/') {
        my $rest = trim(substr $body, 1);
        if (length $rest == 0) {
            return _escape($tag);
        }
        my ($name) = split /\s+/, $rest;
        if (length $name && $allowed_tags->{$name}) {
            return "</" . $name . ">";
        }
        return _escape($tag);
    }

    my $terms = _split_body($body);
    my $name = shift @$terms;

    my $allowed = $allowed_tags->{$name};
    if (!$allowed) {
        return _escape($tag);
    }

    my $valid = 0;
    for (my $i = 0; $i < @$terms; $i++) {
        $valid = 0;
        my ($ename) = split /=/, $terms->[$i];
        for (my $j = 0; $j < @$allowed; $j++) {
            if ($ename eq $allowed->[$i]) {
                $valid = 1;
                last;
            }
        }
        if (!$valid) {
            last;
        }
    }
    if ($valid) {
        return $tag;
    } else {
        return _escape($tag);
    }
}

sub _split_body {
    my $body = shift;
    my $rexes = [
                 '\A([^\s=]+="[^"]*")\s*(.*)\z',
                 q|\A([^\s=]+='[^']*')\s*(.*)\z|,
                 '\A([^\s=]+=\S+)\s*(.*)\z',
                 '\A(\S+)\s*(.*)\z',
    ];
    my $results = [];

    while(length $body) {
        my $k = @$rexes;
        my ($m1, $m2);

        for (my $i = 0; $i < @$rexes; $i++) {
            my $r = $rexes->[$i];
            if ($body =~ /$r/) {
                $m1 = $1;
                $m2 = $2;
                last;
            }
        }
        if (!$m1) {
            last;
        }
        push @$results, $m1;
        if ($m2) {
            $body = $m2;
            $m2 = undef;
        } else {
            last;
        }
    }
    return $results;
}

sub _escape {
    my $t = shift;
    $t =~ s/&(?!|lt;|gt;)/&amp;/g;
    $t =~ s/</&lt;/g;
    $t =~ s/>/&gt;/g;
    return $t;
}

sub escape_html {
    my ($allowed_tags, $text) = @_;
    my $cursor = 0;
    my $last = 0;
    my @results;
    my $in_tag = 0;
    my $in_attr = 0;
    my $start_quote = "";
    my $s;
    my $e;

    while ($cursor < length $text) {
        if ($in_attr) {
            if (substr($text, $cursor, 1) eq $start_quote) {
                $in_attr = 0;
            }
            $cursor++;
            next;
        }

        if ($in_tag) {
            if (substr($text, $cursor, 1) eq '>') {
                $cursor++;
                $s = substr($text, $last, ($cursor - $last));
                $e = escape_tag($allowed_tags, $s);
                push @results, $e;
                $last = $cursor;
                $in_tag = 0;
                next;
            }

            if (substr($text, $cursor, 1) eq '<') {
                if ($last != $cursor) {
                    $s = substr($text, $last, ($cursor - $last));
                    $e = _escape($s);
                    push @results, $e;
                    $last = $cursor;
                }
                $cursor++;
                next;
            }
            if (substr($text, $cursor, 1) eq '"') {
                $in_attr = 1;
                $start_quote = '"';
                $cursor++;
                next;
            }
            if (substr($text, $cursor, 1) eq "'") {
                $in_attr = 1;
                $start_quote = "'";
                $cursor++;
                next;
            }
        }
        if (substr($text, $cursor, 1) eq '<') {
            $in_tag = 1;
            if ($last != $cursor) {
                $s = substr($text, $last, ($cursor - $last));
                $e = _escape($s);
                push @results, $e;
                $last = $cursor;
            }
            $cursor++;
            next;
        }

        if (substr($text, $cursor, 1) eq '>') {
            $cursor++;
            if ($last != $cursor) {
                $s = substr($text, $last, ($cursor - $last));
                $e = _escape($s);
                push @results, $e;
                $last = $cursor;
            }
            next;
        }
        $cursor++;
        next;
    }
    if ($last != $cursor) {
        $s = substr($text, $last, ($cursor - $last));
        $e = _escape($s);
        push @results, $e;
        $last = $cursor;
    }

    return join "", @results;
}

1;
