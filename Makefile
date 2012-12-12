TARGET = siphon2
CODE_MIRROR = ~/Downloads/codemirror-2.36
$(TARGET).min.js: $(TARGET).js
	uglifyjs $< > $@

$(TARGET).js: samples.coffee flick_keys.coffee siphon.coffee
	coffee -cj $(TARGET) $^

push:
	git push origin gh-pages

codemirror:
	cp -R $(CODE_MIRROR)/lib/ lib
	cp -R $(CODE_MIRROR)/mode/xml/ mode/xml
	cp -R $(CODE_MIRROR)/mode/less/ mode/less
	cp -R $(CODE_MIRROR)/mode/css/ mode/css
	cp -R $(CODE_MIRROR)/mode/javascript/ mode/javascript
	cp -R $(CODE_MIRROR)/mode/coffeescript/ mode/coffeescript
