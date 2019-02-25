#!/usr/bin/python
import sys
import re

rex_function = re.compile(ur"^\s*function\s+(\w+)\s*\(([^)]+)\)\s*{\s*$")
rex_js_begin = re.compile(ur"^\s*//JS:ONLY")
rex_js_end = re.compile(ur"^\s*//END")
rex_pl_begin = re.compile(ur"^\s*/\*\s+PL:ONLY")
rex_pl_end = re.compile(ur"^\s*END\s+\*/")
rex_var = re.compile(ur"(var|const)")
rex_foreach = re.compile(ur"(\$\w+)\.forEach\s*\(\s*(\$\w+)\s+=>\s+{")
rex_foreach_end = re.compile(ur"}\);")
rex_comment = re.compile(ur"//")
rex_method_call = re.compile(ur"(\$[\w\->{}()[\]]+\.)")
rex_rex = re.compile(ur"([( \s]+)\/([^/]+?)\/(?:m|g|mg|gm)?([ ,;)])")
rex_object_keys = re.compile(ur"Object.keys\(\s*(\$\w+)\s*\)")
rex_triple_equal = re.compile(ur"([!=]=)=")
rex_index_ref = re.compile(ur"(\))(\[\d+\])")
rex_array_index = re.compile(ur"(\w)\[(\d+)\]")
rex_hash_index = re.compile(ur"(\w)\[(.*?)\]")
rex_break = re.compile(ur"break;");
rex_continue = re.compile(ur"continue;");
rex_null = re.compile(ur"(\W)(null|undefined)(\W)");

def main():
    js_only = 0
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

        # delete PL:ONLY
        if rex_pl_begin.match(l) or rex_pl_end.match(l):
            continue

        # break
        m = rex_break.search(l)
        if m:
            l = rex_break.sub("last;", l)

        # continue
        m = rex_continue.search(l)
        if m:
            l = rex_continue.sub("next;", l)

        # null
        m = rex_null.search(l)
        if m:
            s = m.group(1) + "undef" + m.group(3)
            l = rex_null.sub(s, l)

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

        # ===, !==
        m = rex_triple_equal.search(l)
        if m:
            l = rex_triple_equal.sub(m.group(1), l)

        # method call
        m = rex_method_call.search(l)
        while m:
            s = m.group(1)
            s = s.replace(".", "->")
            l = rex_method_call.sub(s, l)
            m = rex_method_call.search(l)

        # index ref
        m = rex_index_ref.search(l)
        if m:
            s = m.group(1) + "->" + m.group(2)
            l = rex_index_ref.sub(s, l)

        # array_index
        m = rex_array_index.search(l)
        if m:
            s = m.group(1) + "->[" + m.group(2) + "]"
            l = rex_array_index.sub(s, l)

        # hash_index
        m = rex_hash_index.search(l)
        if m:
            s = m.group(1) + "->{" + m.group(2) + "}"
            l = rex_hash_index.sub(s, l)

        # rex
        m = rex_rex.search(l)
        if m:
            s = m.group(2).replace("\\", "\\\\");
            s = m.group(1) + 'qr/' + s + '/' + m.group(3)
            l = rex_rex.sub(s, l)

        # done
        print l
    print "\n1;\n"

if __name__ == '__main__':
    main()
