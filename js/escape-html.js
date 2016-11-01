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

function blank_line_to_paragraph($text) {
  const $lines = $text.split(/(\r\n|\n|\r)/);
  const $blank = /^\s*$/;
  var $results = array(["<p>"]);
  var $cont = 0;
  $lines.forEach($l => {
    if ($blank.exec($l)) {
      if (!$cont) {
        $cont = 1;
        $results.push("</p><p>");
      }
    } else {
      $results.push($l);
      $cont = 0;
    }
  });
  $results.push("</p>");
  return $results.join("\n");
}

function _escape_tag($allowed_tags, $tag) {
  if (Object.keys($allowed_tags).length === 0) {
    return to_entity(tag);
  }
  const $rex = regex(/^<(.*)>$/m);
  const $m = $rex.exec($tag);
  if ($m == null) {
    return to_entity($tag);
  }
  const $body = $m[1].trim();
  if ($body.length == 0) {
    return to_entity($tag);
  }
  // check if end tag?
  if ($body.charAt(0) == '/') {
    const $rest = $body.slice(1).trim();
    if ($rest.length == 0) {
      return to_entity($tag);
    }
    var $name = $rest.split(/\s+/, 1)[0];
    if ($name.length && $allowed_tags[$name]) {
      return "</" + $name + ">";
    } 
    return to_entity($tag);
  }

  const $terms = _split_body($body);
  var $name = $terms.shift();

  const $allowed = $allowed_tags[$name];
  if (!$allowed) {
    return to_entity($tag);
  }

  var $valid = 0;
  for (var $i = 0; $i < $terms.length; $i++) {
    $valid = 0;
    var $ename = $terms[$i].split("=", 1)[0];
    for (var $j = 0; $j < $allowed.length; $j++) {
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

function _split_body($body) {
  const $rexes = [
      /^([^\s=]+="[^"]*")\s*(.*)$/mg,
      /^([^\s=]+='[^']*')\s*(.*)$/mg,
      /^([^\s=]+=\S+)\s*(.*)$/mg,
      /^(\S+)\s*(.*)$/mg,
  ];
  const $results = make_array([]);

  while($body.length) {
    var $m = null;
    for (var $i = 0; $i < $rexes.length && !$m; $i++) {
      $m = $rexes[$i].exec($body);
    }
    if (!$m) {
      break;
    }
    $results.push($m[1]);
    if ($m[2]) {
      $body = $m[2];
    } else {
      break;
    }
  }
  return $results;
}

function to_entity($tag) {
  var $t = $tag.replace(/&(?!|lt;|gt;)/gm, '&amp;');
  $t = $t.replace(/</gm, '&lt;');
  $t = $t.replace(/>/gm, '&gt;');
  return $t;
}

function _slice_and_push($results, $text, $last, $cursor, $allowed_tags) {
  var $s = $text.slice($last, $cursor);
  if ($allowed_tags !== undefined) {
    $s = _escape_tag($allowed_tags, $s);
    $results.push($s);
  } else {
    $results.push(to_entity($s));
  }
}

function escape($allowed_tags, $text) {
  var $cursor = 0;
  var $last = 0;
  var $results = make_array([]);
  var $in_tag = 0;
  var $in_attr = 0;
  var $start_quote = "";

  while($cursor < $text.length) {
    if ($in_attr) {
      if ($text.charAt($cursor) === $start_quote) {
        $in_attr = 0;
      }
      $cursor++;
      continue;
    }

    if ($in_tag) {
      if ($text.charAt($cursor) === '>') {
        $cursor++;
        _slice_and_push($results, $text, $last, $cursor, $allowed_tags);
        $last = $cursor;
        $in_tag = 0;
        continue;
      }
      if ($text.charAt($cursor) === '<') {
        if ($last != $cursor) {
          _slice_and_push($results, $text, $last, $cursor);
          $last = $cursor;
        }
        $cursor++;
        continue;
      }
      if ($text.charAt($cursor) === '"') {
        $in_attr = 1;
        $start_quote = '"';
        $cursor++;
        continue;
      }
      if ($text.charAt($cursor) === "'") {
        $in_attr = 1;
        $start_quote = "'";
        $cursor++;
        continue;
      }
    }
    if ($text.charAt($cursor) === '<') {
      $in_tag = 1;
      if ($last != $cursor) {
        _slice_and_push($results, $text, $last, $cursor);
        $last = $cursor;
      }
      $cursor++;
      continue;
    }

    if ($text.charAt($cursor) === '>') {
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

