var eh = {};

try {
    if (exports === undefined) {
        exports.blank_line_to_paragraph = blank_line_to_paragraph;
        exports.escape = escape;
    } else {
        eh.blank_line_to_paragraph = blank_line_to_paragraph;
        eh.escape = escape;
    }
}
catch (e) {
    eh.blank_line_to_paragraph = _eh_blank_line_to_paragraph;
    eh.escape = _eh_escape;
}

function _eh_blank_line_to_paragraph(text) {
  const lines = text.split(/(\r\n|\n|\r)/);
  const blank = /^\s*$/;
  var results = ["<p>"];
  var cont = 0;
  lines.forEach(l => {
    if (blank.exec(l)) {
      if (!cont) {
        cont = 1;
        results.push("</p><p>");
      }
    } else {
      results.push(l);
      cont = 0;
    }
  });
  results.push("</p>");
  return results.join("\n");
}

function _escape_tag(allowed_tags, tag) {
  const rex = /^<(.*)>$/m;
  const m = rex.exec(tag);
  if (m === null) {
    return _escape(tag);
  }
  const body = m[1].trim();
  if (body.length == 0) {
    return _escape(tag);
  }

  // check if end tag?
  if (body.charAt(0) == '/') {
    const rest = body.slice(1).trim();
    if (rest.length == 0) {
      return _escape(tag);
    }
    var name = rest.split(/\s+/, 1)[0];
    if (name.length && allowed_tags[name]) {
      return "</" + name + ">";
    } 
    return _escape(tag);
  }

  const terms = _split_body(body);
  var name = terms.shift();

  const allowed = allowed_tags[name];
  if (allowed === undefined) {
    return _escape(tag);
  }

  var valid = 1;
  for (var i = 0; i < terms.length; i++) {
    valid = 0;
    var ename = terms[i].split("=", 1)[0];
    for (var j = 0; j < allowed.length; j++) {
      if (ename == allowed[i]) {
        valid = 1;
        break;
      }
    }
    if (!valid) {
      break;
    }
  }
  if (valid) {
    return tag;
  } else {
    return _escape(tag);
  }
}

function _split_body(body) {
  const rexes = [
      /^([^\s=]+="[^"]*")\s*(.*)$/mg,
      /^([^\s=]+='[^']*')\s*(.*)$/mg,
      /^([^\s=]+=\S+)\s*(.*)$/mg,
      /^(\S+)\s*(.*)$/mg,
  ];
  const results = [];

  while(body.length) {
    var m = null;
    for (var i = 0; i < rexes.length && !m; i++) {
      m = rexes[i].exec(body);
    }
    if (!m) {
      break;
    }
    results.push(m[1]);
    if (m[2]) {
      body = m[2];
    } else {
      break;
    }
  }
  return results;
}

function _escape(tag) {
  var t = tag.replace(/&(?!|lt;|gt;)/gm, '&amp;');
  var t = t.replace(/</gm, '&lt;');
  var t = t.replace(/>/gm, '&gt;');
  return t;
}

function _eh_escape(allowed_tags, text) {
  var cursor = 0;
  var last = 0;
  var results = [];
  var in_tag = 0;
  var in_attr = 0;
  var start_quote = "";

  while(cursor < text.length) {
    if (in_attr) {
      if (text.charAt(cursor) === start_quote) {
        in_attr = 0;
      }
      cursor++;
      continue;
    }

    if (in_tag) {
      if (text.charAt(cursor) === '>') {
        cursor++;
        var s = text.slice(last, cursor);
        s = _escape_tag(allowed_tags, s);
        results.push(s);
        last = cursor;
        in_tag = 0;
        continue;
      }
      if (text.charAt(cursor) === '<') {
        if (last != cursor) {
          var s = text.slice(last, cursor);
          results.push(_escape(s));
          last = cursor;
        }
        cursor++;
        continue;
      }
      if (text.charAt(cursor) === '"') {
        in_attr = 1;
        start_quote = '"';
        cursor++;
        continue;
      }
      if (text.charAt(cursor) === "'") {
        in_attr = 1;
        start_quote = "'";
        cursor++;
        continue;
      }
    }
    if (text.charAt(cursor) === '<') {
      in_tag = 1;
      if (last != cursor) {
        var s = text.slice(last, cursor);
        results.push(_escape(s));
        last = cursor;
      }
      cursor++;
      continue;
    }

    if (text.charAt(cursor) === '>') {
      cursor++;
      if (last != cursor) {
        var s = text.slice(last, cursor);
        results.push(_escape(s));
        last = cursor;
      }
      continue;
    }
    cursor++;
    continue;
  }
  if (last != cursor) {
    var s = text.slice(last, cursor);
    results.push(_escape(s));
    last = cursor;
  }

  return results.join("");
}

