#!/usr/bin/python
import sys
import re

rex_function = re.compile(ur"^function\s+(\w+)\s*\(([^)]+)\)\s*{\s*$")
rex_js_begin = re.compile(ur"^//JS:ONLY")
rex_js_end = re.compile(ur"^//END")
rex_var = re.compile(ur"(var|const)")
rex_foreach = re.compile(ur"(\$\w+)\.forEach\s*\(\s*(\$\w+)\s+=>\s+{")
rex_foreach_end = re.compile(ur"}\);")
rex_comment = re.compile(ur"//")
rex_method_call = re.compile(ur"(\$[\w\->{}]+\.)")
rex_rex = re.compile(ur"([( \s]+)\/([^/]+?)\/(?:m|g|mg|gm)?([ ,;)])")
rex_object_keys = re.compile(ur"Object.keys\(\s*(\$\w+)\s*\)")
rex_triple_equal = re.compile(ur"===")

def main():
    js_only = 0
    print "use 'Js2pl.pm';\n";
    for l in sys.stdin:
        l = l.rstrip()

        # delete JS:ONLY
        if js_only:
            m = rex_js_end.match(l)
            if m:
                js_only = 0
            continue
        m = rex_js_begin.match(l)
        if m:
            js_only = 1
            continue

        # replace "function" to "sub"
        m = rex_function.match(l)
        if m:
            print "sub " + m.group(1) + " {"
            print "  my (" + m.group(2) + ") = @_;\n"
            continue

        # replace "var" and "const" to "my"
        m = rex_var.search(l)
        if m:
            l = rex_var.sub("my", l)

        # replace ".forEach"
        m = rex_foreach.search(l)
        if m:
            s = "for my {0} (@{{{1}->self}}) {{"
            s = s.format(m.group(2), m.group(1));
            l = rex_foreach.sub(s, l)

        m = rex_foreach_end.search(l)
        if m:
            l = rex_foreach_end.sub("}", l)

        # Object.keys
        #ur"Object.keys\(\s*(\$\w+)\s*)\)"
        m = rex_object_keys.search(l)
        if m:
            s = m.group(1) + "->keys";
            l = rex_object_keys.sub(s, l)

        # comment
        m = rex_comment.search(l)
        if m:
            l = rex_comment.sub("#", l)

        # ===
        m = rex_triple_equal.search(l)
        if m:
            l = rex_triple_equal.sub("==", l)

        # method call
        m = rex_method_call.search(l)
        if m:
            s = m.group(1)
            s = s.replace(".", "->")
            l = rex_method_call.sub(s, l)

        # rex
        m = rex_rex.search(l)
        if m:
            s = m.group(2).replace("\\", "\\\\");
            s = m.group(1) + '"' + s + '"' + m.group(3)
            l = rex_rex.sub(s, l)

        # done
        print l

if __name__ == '__main__':
    main()
