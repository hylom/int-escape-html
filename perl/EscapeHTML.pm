
package EscapeHTML;
use strict;
use warnings;
use utf8;
use Data::Dumper;
use Js2pl;

sub blank_line_to_paragraph {
  my ($text) = @_;

  $text = string($text);
  my $lines = $text->split(qr/\n/);
  my $blank = qr/^\s*$/;
  my $results = array([string("<p>")]);
  my $cont = 0;

  for my $l (@{$lines->self}) {
    if ($l->match($blank)) {
      if (!$cont) {
        $cont = 1;
        $results->push(string("</p><p>"));
      }
    } else {
      $results->push($l);
      $cont = 0;
    }
  }
  $results->push(string("</p>"));
  return $results->join("\n");
}

sub _escape_tag {
  my ($allowed_tags, $tag) = @_;

  if ($allowed_tags->keys->length == 0) {
    return _to_entity($tag);
  }
  my $rex = regex(qr/^<(.*)>$/);
  my $m = $rex->exec($tag);
  if (!$m) {
    return _to_entity($tag);
  }
  my $body = string($m->[1])->trim();
  if ($body->length == 0) {
    return _to_entity($tag);
  }
  # check if end tag?
  if (_char_at_eq($body, 0, '/')) {
    my $rest = $body->slice(1)->trim();
    if ($rest->length == 0) {
      return _to_entity($tag);
    }
    my $splited = $rest->split(qr/\s+/, 1);
    my $name = $splited->shift();
    my $raw_name = $name->{string};
    if ($name->length
        && $allowed_tags->{hash}->{$raw_name}) {
        return string("</" . $raw_name . ">");
    }
    return _to_entity($tag);
  }

  my $terms = _split_body($body);
  my $name = $terms->shift();

  my $allowed = $allowed_tags->{hash}->{$name};
  $allowed = array($allowed);
  if (!$allowed) {
    return _to_entity($tag);
  }
  if ($allowed->length == 0) {
    return $tag;
  }

  my $valid = 0;
  for (my $i = 0; $i < $terms->length; $i++) {
    $valid = 0;
    my $el = string($terms->{array}->[$i]);
    my $ename = $el->split("=", 1)->shift()->{string};
    for (my $j = 0; $j < $allowed->length; $j++) {
      if ($ename eq $allowed->{array}->[$i]) {
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
    return _to_entity($tag);
  }
}

sub _split_body {
  my ($body) = @_;

  my $rexes = array([
      qr/^([^\s=]+="[^"]*")\s*(.*)$/,
      qr/^([^\s=]+='[^']*')\s*(.*)$/,
      qr/^([^\s=]+=\S+)\s*(.*)$/,
      qr/^(\S+)\s*(.*)$/,
  ]);
  my $results = array([]);

  while($body && $body->length) {
    my $m = undef;
    for (my $i = 0; $i < $rexes->length && !$m; $i++) {
      $m = $body->match($rexes->{array}->[$i]);
    }
    if (!$m) {
      last;
    }
    $results->push($m->[1]);
    $body = string($m->[2]);
    #$m->shift();
    #$results->push($results->shift());
    #$body = $m->shift();
  }
  return $results;
}

sub _to_entity {
  my ($tag) = @_;

  my $t = $tag->replace(qr/&(?!|lt;|gt;)/, '&amp;');
  $t = $t->replace(qr/</, '&lt;');
  $t = $t->replace(qr/>/, '&gt;');
  return $t;
}

sub _slice_and_push {
  my ($results, $text, $last, $cursor, $allowed_tags) = @_;

  my $s = $text->slice($last, $cursor);
  if ($allowed_tags) {
    $s = _escape_tag($allowed_tags, $s);
    $results->push($s);
  } else {
    $results->push(_to_entity($s));
  }
}

sub _char_at_eq {
  my ($string, $index, $char) = @_;

  return $string->charAt($index) eq $char;
}

sub escape {
  my ($allowed_tags, $text) = @_;

  my $cursor = 0;
  my $last = 0;
  my $results = array([]);
  my $in_tag = 0;
  my $in_attr = 0;
  my $start_quote = "";

  $text = string($text);
  $allowed_tags = hash($allowed_tags);

  while($cursor < $text->length) {
    if ($in_attr) {
      if (_char_at_eq($text, $cursor, $start_quote)) {
        $in_attr = 0;
      }
      $cursor++;
      next;
    }

    if ($in_tag) {
      if (_char_at_eq($text, $cursor, '>')) {
        $cursor++;
        _slice_and_push($results, $text, $last, $cursor, $allowed_tags);
        $last = $cursor;
        $in_tag = 0;
        next;
      }
      if (_char_at_eq($text, $cursor, '<')) {
        if ($last != $cursor) {
          _slice_and_push($results, $text, $last, $cursor);
          $last = $cursor;
        }
        $cursor++;
        next;
      }
      if (_char_at_eq($text, $cursor, '"')) {
        $in_attr = 1;
        $start_quote = '"';
        $cursor++;
        next;
      }
      if (_char_at_eq($text, $cursor, "'")) {
        $in_attr = 1;
        $start_quote = "'";
        $cursor++;
        next;
      }
    }
    if (_char_at_eq($text, $cursor, '<')) {
      $in_tag = 1;
      if ($last != $cursor) {
        _slice_and_push($results, $text, $last, $cursor);
        $last = $cursor;
      }
      $cursor++;
      next;
    }

    if (_char_at_eq($text, $cursor, '>')) {
      $cursor++;
      if ($last != $cursor) {
        _slice_and_push($results, $text, $last, $cursor);
        $last = $cursor;
      }
      next;
    }
    $cursor++;
    next;
  }
  if ($last != $cursor) {
    _slice_and_push($results, $text, $last, $cursor);
    $last = $cursor;
  }
  return $results->join("");
}


1;

