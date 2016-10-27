use 'Js2pl.pm';


sub blank_line_to_paragraph {
  my ($text) = @_;

  my $lines = $text->split("(\r\n|\n|\r)");
  my $blank = "^\s*$";
  my $results = array(["<p>"]);
  my $cont = 0;
  for my $l (@{$lines->self}) {
    if ($blank->exec($l)) {
      if (!$cont) {
        $cont = 1;
        $results->push("</p><p>");
      }
    } else {
      $results->push($l);
      $cont = 0;
    }
  }
  $results->push("</p>");
  return $results->join("\n");
}

sub _escape_tag {
  my ($allowed_tags, $tag) = @_;

  if ($allowed_tags->keys->length == 0) {
    return to_entity(tag);
  }
  my $rex = regex("^<(.*)>$");
  my $m = $rex->exec($tag);
  if ($m == null) {
    return to_entity($tag);
  }
  my $body = $m[1].trim();
  if ($body->length == 0) {
    return to_entity($tag);
  }
  # check if end tag?
  if ($body->charAt(0) == '/') {
    my $rest = $body->slice(1).trim();
    if ($rest->length == 0) {
      return to_entity($tag);
    }
    my $name = $rest->split("\s+", 1)[0];
    if ($name->length && $allowed_tags[$name]) {
      return "</" + $name + ">";
    }
    return to_entity($tag);
  }

  my $terms = _split_body($body);
  my $name = $terms->shift();

  my $allowed = $allowed_tags[$name];
  if (!$allowed) {
    return to_entity($tag);
  }

  my $valid = 0;
  for (my $i = 0; $i < $terms->length; $i++) {
    $valid = 0;
    my $ename = $terms[$i].split("=", 1)[0];
    for (my $j = 0; $j < $allowed->length; $j++) {
      if ($ename == $allowed[$i]) {
        $valid = 1;
        break;
      }
    }
    if (!$valid) {
      break;
    }
  }
  if ($valid) {
    return $tag;
  } else {
    return to_entity($tag);
  }
}

sub _split_body {
  my ($body) = @_;

  my $rexes = [
      "^([^\s=]+="[^"]*")\s*(.*)$",
      "^([^\s=]+='[^']*')\s*(.*)$",
      "^([^\s=]+=\S+)\s*(.*)$",
      "^(\S+)\s*(.*)$",
  ];
  my $results = make_array([]);

  while($body->length) {
    my $m = null;
    for (my $i = 0; $i < $rexes->length && !$m; $i++) {
      $m = $rexes[$i].exec($body);
    }
    if (!$m) {
      break;
    }
    $results->push($m[1]);
    if ($m[2]) {
      $body = $m[2];
    } else {
      break;
    }
  }
  return $results;
}

sub to_entity {
  my ($tag) = @_;

  my $t = $tag->replace("&(?!|lt;|gt;)", '&amp;');
  $t = $t->replace("<", '&lt;');
  $t = $t->replace(">", '&gt;');
  return $t;
}

sub _slice_and_push {
  my ($results, $text, $last, $cursor, $allowed_tags) = @_;

  my $s = $text->slice($last, $cursor);
  if ($allowed_tags !== undefined) {
    $s = _escape_tag($allowed_tags, $s);
    $results->push($s);
  } else {
    $results->push(to_entity($s));
  }
}

sub escape {
  my ($allowed_tags, $text) = @_;

  my $cursor = 0;
  my $last = 0;
  my $results = make_array([]);
  my $in_tag = 0;
  my $in_attr = 0;
  my $start_quote = "";

  while($cursor < $text->length) {
    if ($in_attr) {
      if ($text->charAt($cursor) == $start_quote) {
        $in_attr = 0;
      }
      $cursor++;
      continue;
    }

    if ($in_tag) {
      if ($text->charAt($cursor) == '>') {
        $cursor++;
        _slice_and_push($results, $text, $last, $cursor, $allowed_tags);
        $last = $cursor;
        $in_tag = 0;
        continue;
      }
      if ($text->charAt($cursor) == '<') {
        if ($last != $cursor) {
          _slice_and_push($results, $text, $last, $cursor);
          $last = $cursor;
        }
        $cursor++;
        continue;
      }
      if ($text->charAt($cursor) == '"') {
        $in_attr = 1;
        $start_quote = '"';
        $cursor++;
        continue;
      }
      if ($text->charAt($cursor) == "'") {
        $in_attr = 1;
        $start_quote = "'";
        $cursor++;
        continue;
      }
    }
    if ($text->charAt($cursor) == '<') {
      $in_tag = 1;
      if ($last != $cursor) {
        _slice_and_push($results, $text, $last, $cursor);
        $last = $cursor;
      }
      $cursor++;
      continue;
    }

    if ($text->charAt($cursor) == '>') {
      $cursor++;
      if ($last != $cursor) {
        _slice_and_push($results, $text, $last, $cursor);
        $last = $cursor;
      }
      continue;
    }
    $cursor++;
    continue;
  }
  if ($last != $cursor) {
    _slice_and_push($results, $text, $last, $cursor);
    $last = $cursor;
  }
  return $results->join("");
}

