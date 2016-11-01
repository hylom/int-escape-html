all: EscapeHTML.pm

EscapeHTML.pm: Js2pl.pm js2pl.py ../js/escape-html.js
	python js2pl.py < ../js/escape-html.js > $@

test: EscapeHTML.pm
	perl t/test.pl 
