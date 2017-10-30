//JS:ONLY
var eh = {};

try {
  if (exports !== undefined) {
    exports.blank_line_to_paragraph = blank_line_to_paragraph;
    exports.escape = escape;
  } else {
    eh.blank_line_to_paragraph = blank_line_to_paragraph;
    eh.escape = escape;
  }
}
catch (e) {
  eh.blank_line_to_paragraph = blank_line_to_paragraph;
  eh.escape = escape;
}

function array(ar) {
  return ar;
}
function hash(ha) {
  return ha;
}
function regex(re) {
  return re;
}
function string(str) {
  return str;
}
//END

/* PL:ONLY
package EscapeHTML;
use strict;
use warnings;
use utf8;
use Data::Dumper;
use Js2pl;
END */

function blank_line_to_paragraph($text) {
  /* PL:ONLY
  $text = string($text);
  END */
  const $lines = $text.split(/\n/);
  const $blank = /^\s*$/;
  var $results = array([string("<p>")]);
  var $cont = 0;

  $lines.forEach($l => {
    if ($l.match($blank)) {
      if (!$cont) {
        $cont = 1;
        $results.push(string("</p><p>"));
      }
    } else {
      $results.push($l);
      $cont = 0;
    }
  });
  $results.push(string("</p>"));
  return $results.join("\n");
}

function _escape_tag($allowed_tags, $tag) {
  if (Object.keys($allowed_tags).length === 0) {
    return _to_entity($tag);
  }
  const $rex = regex(/^<(.*)>$/m);
  const $m = $rex.exec($tag);
  if (!$m) {
    return _to_entity($tag);
  }
  const $body = string($m[1]).trim();
  if ($body.length == 0) {
    return _to_entity($tag);
  }
  // check if end tag?
  if (_char_at_eq($body, 0, '/')) {
    const $rest = $body.slice(1).trim();
    if ($rest.length == 0) {
      return _to_entity($tag);
    }
    var $splited = $rest.split(/\s+/, 1);
    var $name = $splited.shift();
    //JS:ONLY
    $name = $name.toLowerCase();
    if ($name.length && $allowed_tags[$name]) {
      return "</" + $name + ">";
    } 
    //END
    /* PL:ONLY
    my $raw_name = $name->{string};
    $raw_name = lc($raw_name);
    if ($name->length
        && $allowed_tags->{hash}->{$raw_name}) {
        return string("</" . $raw_name . ">");
    } 
    END  */
    return _to_entity($tag);
  }

  const $terms = _split_body($body);
  var $name = $terms.shift();
  //JS:ONLY
  $name = $name.toLowerCase();
  //END
  /* PL:ONLY
  $name = lc($name);
  END  */

  //JS:ONLY
  const $allowed = $allowed_tags[$name];
  //END
  /* PL:ONLY
  my $allowed = $allowed_tags->{hash}->{$name};
  $allowed = array($allowed);
  END */
  if (!$allowed) {
    return _to_entity($tag);
  }
  if ($allowed.length == 0) {
    return $tag;
  }

  var $valid = 1;
  for (var $i = 0; $i < $terms.length; $i++) {
    //JS:ONLY
    var $ename = string($terms[$i]).split("=", 1).shift();
    //END
    /* PL:ONLY
    my $el = string($terms->{array}->[$i]);
    my $ename = $el->split("=", 1)->shift()->{string};
    END */
    for (var $j = 0; $j < $allowed.length; $j++) {
      //JS:ONLY
      if ($ename != $allowed[$i]) {
      //END
      /* PL:ONLY
      if ($ename ne $allowed->{array}->[$i]) {
      END */
        $valid = 0;
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
    return _to_entity($tag);
  }
}

function _split_body($body) {
  const $rexes = array([
      /^([^\s=]+="[^"]*")\s*(.*)$/m,
      /^([^\s=]+='[^']*')\s*(.*)$/m,
      /^([^\s=]+=\S+)\s*(.*)$/m,
      /^(\S+)\s*(.*)$/m,
  ]);
  const $results = array([]);

  while($body && $body.length) {
    var $m = null;
    for (var $i = 0; $i < $rexes.length && !$m; $i++) {
      //JS:ONLY
      $m = $body.match($rexes[$i]);
      //END
      /* PL:ONLY
      $m = $body->match($rexes->{array}->[$i]);
      END */
    }
    if (!$m) {
      break;
    }
    $results.push($m[1]);
    $body = string($m[2]);
    //$m.shift();
    //$results.push($m.shift());
    //$body = $m.shift();
  }
  return $results;
}

function _to_entity($tag) {
  var $t = $tag.replace(/&(?!|lt;|gt;)/gm, '&amp;');
  $t = $t.replace(/</gm, '&lt;');
  $t = $t.replace(/>/gm, '&gt;');
  return $t;
}

function _slice_and_push($results, $text, $last, $cursor, $allowed_tags) {
  var $s = $text.slice($last, $cursor);
  if ($allowed_tags) {
    $s = _escape_tag($allowed_tags, $s);
    $results.push($s);
  } else {
    $results.push(_to_entity($s));
  }
}

function _char_at_eq($string, $index, $char) {
  //JS:ONLY
  return $string.charAt($index) == $char;
  //END
  /* PL:ONLY
  return $string->charAt($index) eq $char;
  END */
}

function escape_tag($allowed_tags, $tag_text) {
  /* PL:ONLY
  $tag_text = string($tag_text);
  $allowed_tags = hash($allowed_tags);
   END */
  var $results = array([]);
  var $s = _escape_tag($allowed_tags, $tag_text);
  $results.push($s);
  return $results.join("");

}

function escape($allowed_tags, $text) {
  var $cursor = 0;
  var $last = 0;
  var $results = array([]);
  var $in_tag = 0;
  var $in_attr = 0;
  var $start_quote = "";

  /* PL:ONLY
  $text = string($text);
  $allowed_tags = hash($allowed_tags);
  END */

  while($cursor < $text.length) {
    if ($in_attr) {
      if (_char_at_eq($text, $cursor, $start_quote)) {
        $in_attr = 0;
      }
      $cursor++;
      continue;
    }

    if ($in_tag) {
      if (_char_at_eq($text, $cursor, '>')) {
        $cursor++;
        _slice_and_push($results, $text, $last, $cursor, $allowed_tags);
        $last = $cursor;
        $in_tag = 0;
        continue;
      }
      if (_char_at_eq($text, $cursor, '<')) {
        if ($last != $cursor) {
          _slice_and_push($results, $text, $last, $cursor);
          $last = $cursor;
        }
        $cursor++;
        continue;
      }
      if (_char_at_eq($text, $cursor, '"')) {
        $in_attr = 1;
        $start_quote = '"';
        $cursor++;
        continue;
      }
      if (_char_at_eq($text, $cursor, "'")) {
        $in_attr = 1;
        $start_quote = "'";
        $cursor++;
        continue;
      }
    }
    if (_char_at_eq($text, $cursor, '<')) {
      $in_tag = 1;
      if ($last != $cursor) {
        _slice_and_push($results, $text, $last, $cursor);
        $last = $cursor;
      }
      $cursor++;
      continue;
    }

    if (_char_at_eq($text, $cursor, '>')) {
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
  return $results.join("");
}

