const fs = require('fs');
const util = require('util');
const eh = require('./escape-html');

require('jsdom').env('', (err, window) => {
  if (err) {
    console.error(err);
    return;
  }
  main(require('jquery')(window));
});

function main(jq) {
  const test = '<a href="example.com/><">example.com</a>\nfoo>bar< hoge&lt;hoge<br>\n\n<script>hoge&hoge</script>\n\n\n<blockquote>\n<i>block<strong>hoge</i></strong>quoted!!';

  const allowed_tags = {
    "a": ["href"],
    "p": [],
    "blockquote": [],
    "i": [],
    "strong": [],
  };

  console.log("\n-----input:-----");
  console.log(test);

  console.log("\n-----escaped:-----");
  const escaped = eh.escape(allowed_tags, test);
  console.log(escaped);

  console.log("\n-----quoted:-----");
  const quoted = eh.blank_line_to_paragraph(escaped);
  console.log(quoted);

  console.log("\n-----output:-----");
  const html = jq.parseHTML(quoted, null);
  html.forEach(i => {
    i.normalize();
    console.log(i.outerHTML);
  });
}

//main();
