SRC_JS_FILES := $(shell find src -type f -name '*.js')
SRC_DIRECTIVES_PARTIALS_FILES := $(shell find src/directives -type f -name '*.html')
EXPORTS_JS_FILES := $(shell find exports -type f -name '*.js')

NGEO_SRC_JS_FILES := $(shell find node_modules/ngeo/src -type f -name '*.js')
NGEO_SRC_DIRECTIVES_PARTIALS_FILES := $(shell find node_modules/ngeo/src/directives -type f -name '*.html')
NGEO_EXPORTS_JS_FILES := $(shell find node_modules/ngeo/exports -type f -name '*.js')

EXAMPLES_JS_FILES := $(shell find examples -maxdepth 1 -type f -name '*.js')
EXAMPLES_HTML_FILES := $(shell find examples -maxdepth 1 -type f -name '*.html')

BUILD_EXAMPLES_CHECK_TIMESTAMP_FILES := $(patsubst examples/%.html,.build/%.check.timestamp,$(EXAMPLES_HTML_FILES)) )

EXTERNS_ANGULAR = .build/externs/angular-1.4.js
EXTERNS_ANGULAR_Q = .build/externs/angular-1.4-q_templated.js
EXTERNS_ANGULAR_HTTP_PROMISE = .build/externs/angular-1.4-http-promise_templated.js
EXTERNS_JQUERY = .build/externs/jquery-1.9.js
EXTERNS_FILES = $(EXTERNS_ANGULAR) $(EXTERNS_ANGULAR_Q) $(EXTERNS_ANGULAR_HTTP_PROMISE) $(EXTERNS_JQUERY)

ifeq ($(OS),Darwin)
	STAT_COMPRESSED = stat -f '  compressed: %z bytes'
	STAT_UNCOMPRESSED = stat -f 'uncompressed: %z bytes'
else
	STAT_COMPRESSED = stat -c '  compressed: %s bytes'
	STAT_UNCOMPRESSED = stat -c 'uncompressed: %s bytes'
endif

# Disabling Make built-in rules to speed up execution time
.SUFFIXES:

.PHONY: all
all: help

.PHONY: help
help:
	@echo "Usage: make <target>"
	@echo
	@echo "Possible targets:"
	@echo
	@echo "- dist                    Compile the lib into an ngeo.js standalone build (in dist/)"
	@echo "- check                   Perform a number of checks on the code"
	@echo "- lint                    Check the code with the linter"
	@echo "- test                    Run the test suite"
	@echo "- serve                   Run a development web server for running the examples"
	@echo "- gh-pages                Update the GitHub pages"
	@echo "- clean                   Remove generated files"
	@echo "- cleanall                Remove all the build artefacts"
	@echo "- help                    Display this help message"
	@echo

.PHONY: dist
dist: dist/geoacorda.js dist/geoacorda-debug.js

.PHONY: check
check: lint dist check-examples test compile-examples

.PHONY: compile-examples
compile-examples: .build/examples/all.min.js

.PHONY: check-examples
check-examples: $(BUILD_EXAMPLES_CHECK_TIMESTAMP_FILES)

.PHONY: lint
lint: .build/python-venv/bin/gjslint .build/node_modules.timestamp .build/gjslint.timestamp .build/jshint.timestamp

.PHONY: test
test: .build/ol-deps.js .build/ngeo-deps.js .build/node_modules.timestamp
	./node_modules/karma/bin/karma start karma-conf.js --single-run

.PHONY: serve
serve: .build/node_modules.timestamp
	node buildtools/serve.js

.PHONY: gh-pages
GITHUB_USERNAME ?= camptocamp
GIT_BRANCH ?= $(shell git rev-parse --symbolic-full-name --abbrev-ref HEAD)
gh-pages: GIT_REMOTE_NAME ?= origin
gh-pages: .build/ngeo-$(GITHUB_USERNAME)-gh-pages \
		.build/examples-hosted/index.html
	echo "done"
	# cd $<; git fetch origin
	# cd $<; git merge --ff-only origin/gh-pages
	# cd $<; git rm --ignore-unmatch -rqf $(GIT_BRANCH) examples-$(GIT_BRANCH) aptdoc-$(GIT_BRANCH)
	# cd $<; git clean --force -d
	# mkdir $</$(GIT_BRANCH)
	# cp -r .build/apidoc-$(GIT_BRANCH) $</$(GIT_BRANCH)/apidoc
	# mkdir $</$(GIT_BRANCH)/examples
	# cp -r .build/examples-hosted/* $</$(GIT_BRANCH)/examples
	# cd $<; git add -A
	# cd $<; git status
	# cd $<; git commit -m 'Update GitHub pages'
	# cd $<; git push $(GIT_REMOTE_NAME) gh-pages

.build/ngeo-$(GITHUB_USERNAME)-gh-pages: GIT_REMOTE_URL ?= git@github.com:$(GITHUB_USERNAME)/ngeo.git
.build/ngeo-$(GITHUB_USERNAME)-gh-pages:
	# git clone --branch gh-pages $(GIT_REMOTE_URL) $@
	echo "skip clone"

.build/gjslint.timestamp: $(SRC_JS_FILES) $(EXPORTS_JS_FILES) $(EXAMPLES_JS_FILES) $(GMF_SRC_JS_FILES) $(GMF_EXAMPLES_JS_FILES) $(GMF_APPS_MOBILE_JS_FILES)
	.build/python-venv/bin/gjslint --jslint_error=all --strict --custom_jsdoc_tags=event,fires,function,classdesc,api,observable,example,module,ngdoc,ngname $?
	touch $@

.build/jshint.timestamp: $(SRC_JS_FILES) $(EXPORTS_JS_FILES) $(EXAMPLES_JS_FILES) $(GMF_SRC_JS_FILES) $(GMF_EXAMPLES_JS_FILES) $(GMF_APPS_MOBILE_JS_FILES)
	./node_modules/.bin/jshint --verbose $?
	touch $@

dist/geoacorda.js: buildtools/geoacorda.json \
		$(EXTERNS_FILES) \
		$(SRC_JS_FILES) \
		$(EXPORTS_JS_FILES) \
		$(NGEO_SRC_JS_FILES) \
		$(NGEO_EXPORTS_JS_FILES) \
		.build/node_modules.timestamp
	mkdir -p $(dir $@)
	node buildtools/build.js $< $@
	@$(STAT_UNCOMPRESSED) $@
	@cp $@ /tmp/
	@gzip /tmp/geoacorda.js
	@$(STAT_COMPRESSED) /tmp/geoacorda.js.gz
	@rm /tmp/geoacorda.js.gz

dist/geoacorda-debug.js: buildtools/geoacorda-debug.json \
		$(EXTERNS_FILES) \
		$(SRC_JS_FILES) \
		$(EXPORTS_JS_FILES) \
		$(NGEO_SRC_JS_FILES) \
		$(NGEO_EXPORTS_JS_FILES) \
		.build/node_modules.timestamp
	mkdir -p $(dir $@)
	node buildtools/build.js $< $@
	@$(STAT_UNCOMPRESSED) $@
	@cp $@ /tmp/
	@gzip /tmp/geoacorda-debug.js
	@$(STAT_COMPRESSED) /tmp/geoacorda-debug.js.gz
	@rm /tmp/geoacorda-debug.js.gz

# At this point geoacorda does not include its own CSS, so dist/geoacorda.css is just
# a minified version of ol.css. This will change in the future.
dist/geoacorda.css: node_modules/openlayers/css/ol.css .build/node_modules.timestamp
	mkdir -p $(dir $@)
	./node_modules/.bin/cleancss $< > $@

.PHONY: examples-hosted
examples-hosted: dist/geoacorda.js dist/geoacorda-debug.js dist/geoacorda.css .build/examples-hosted/data .build/examples-hosted/lib/geoacorda.js .build/examples-hosted/lib/geoacorda-debug.js .build/examples-hosted/lib/geoacorda.css .build/examples-hosted/lib/angular.min.js .build/examples-hosted/lib/jquery.min.js .build/examples-hosted/simple.js .build/examples-hosted/simple.html .build/examples-hosted/apidoc

.build/examples/%.min.js: .build/examples/%.json \
		$(SRC_JS_FILES) \
		$(EXPORTS_JS_FILES) \
		$(EXTERNS_FILES) \
		examples/%.js \
		.build/node_modules.timestamp
	mkdir -p $(dir $@)
	node buildtools/build.js $< $@

.build/examples/all.min.js: buildtools/examples-all.json \
		$(SRC_JS_FILES) \
		$(GMF_SRC_JS_FILES) \
		$(EXPORTS_JS_FILES) \
		$(EXTERNS_FILES) \
		.build/examples/all.js \
		.build/node_modules.timestamp
	mkdir -p $(dir $@)
	node buildtools/build.js $< $@

.build/examples/all.js: $(EXAMPLES_JS_FILES) $(GMF_EXAMPLES_JS_FILES) .build/python-venv
	mkdir -p $(dir $@)
	./.build/python-venv/bin/python buildtools/combine-examples.py $(EXAMPLES_JS_FILES) $(GMF_EXAMPLES_JS_FILES) > $@

.PRECIOUS: .build/examples-hosted/lib/%
.build/examples-hosted/lib/%: dist/%
	mkdir -p $(dir $@)
	cp $< $@

.build/examples-hosted/lib/angular.min.js: node_modules/angular/angular.min.js
	mkdir -p $(dir $@)
	cp $< $@

.build/examples-hosted/lib/bootstrap.min.js: node_modules/bootstrap/dist/js/bootstrap.min.js
	mkdir -p $(dir $@)
	cp $< $@

.build/examples-hosted/lib/bootstrap.min.css: node_modules/bootstrap/dist/css/bootstrap.min.css
	mkdir -p $(dir $@)
	cp $< $@

.build/examples-hosted/lib/jquery.min.js: node_modules/jquery/dist/jquery.min.js
	mkdir -p $(dir $@)
	cp $< $@

.build/examples-hosted/lib/d3.min.js: node_modules/d3/d3.min.js
	mkdir -p $(dir $@)
	cp $< $@

.build/examples-hosted/lib/watchwatchers.js: utils/watchwatchers.js
	mkdir -p $(dir $@)
	cp $< $@

.build/examples-hosted/lib/typeahead.bundle.min.js: node_modules/typeahead.js/dist/typeahead.bundle.min.js
	mkdir -p $(dir $@)
	cp $< $@

.build/examples-hosted/partials: examples/partials
	mkdir -p $@
	cp $</* $@

.build/examples-hosted/data: examples/data
	mkdir -p $@
	cp examples/data/* $@

node_modules/angular/angular.min.js: .build/node_modules.timestamp

.PRECIOUS: .build/examples-hosted/%.html
.build/examples-hosted/%.html: examples/%.html
	mkdir -p $(dir $@)
	sed -e 's|\.\./node_modules/openlayers/css/ol.css|lib/geoacorda.css|' \
		-e 's|\.\./node_modules/bootstrap/dist/css/bootstrap.css|lib/bootstrap.min.css|' \
		-e 's|\.\./node_modules/jquery/dist/jquery.js|lib/jquery.min.js|' \
		-e 's|\.\./node_modules/bootstrap/dist/js/bootstrap.js|lib/bootstrap.min.js|' \
		-e 's|\.\./node_modules/angular/angular.js|lib/angular.min.js|' \
		-e 's|\.\./node_modules/d3/d3.js|lib/d3.min.js|' \
		-e 's|\.\./node_modules/typeahead.js/dist/typeahead.bundle.js|lib/typeahead.bundle.min.js|' \
		-e 's|/@?main=$*.js|$*.js|' \
		-e 's|\.\./utils/watchwatchers.js|lib/watchwatchers.js|' \
		-e '/$*.js/i\    <script src="lib/geoacorda.js"></script>' $< > $@

.PRECIOUS: .build/examples-hosted/%.js
.build/examples-hosted/%.js: examples/%.js
	mkdir -p $(dir $@)
	sed -e '/^goog\.provide/d' -e '/^goog\.require/d' $< > $@

.build/examples-hosted/index.html: buildtools/examples-index.mako.html $(EXAMPLES_HTML_FILES) .build/python-venv/bin/mako-render .build/beautifulsoup4.timestamp
	mkdir -p $(dir $@)
	.build/python-venv/bin/python node_modules/ngeo/buildtools/generate-examples-index.py $< $(EXAMPLES_HTML_FILES) > $@

.build/%.check.timestamp: .build/examples-hosted/%.html \
		.build/examples-hosted/%.js \
		.build/examples-hosted/lib/ngeo.js \
		.build/examples-hosted/lib/ngeo-debug.js \
		.build/examples-hosted/lib/ngeo.css \
		.build/examples-hosted/lib/gmf.js \
		.build/examples-hosted/lib/angular.min.js \
		.build/examples-hosted/lib/bootstrap.min.js \
		.build/examples-hosted/lib/bootstrap.min.css \
		.build/examples-hosted/lib/jquery.min.js \
		.build/examples-hosted/lib/d3.min.js \
		.build/examples-hosted/lib/watchwatchers.js \
		.build/examples-hosted/lib/typeahead.bundle.min.js \
		.build/examples-hosted/data \
		.build/examples-hosted/partials \
		.build/node_modules.timestamp
	mkdir -p $(dir $@)
	./node_modules/phantomjs/bin/phantomjs buildtools/check-example.js $<
	touch $@

.build/node_modules.timestamp: package.json
	npm install
	mkdir -p $(dir $@)
	touch $@

.build/closure-compiler/compiler.jar: .build/closure-compiler/compiler-latest.zip
	unzip $< -d .build/closure-compiler
	touch $@

.build/closure-compiler/compiler-latest.zip:
	mkdir -p $(dir $@)
	wget -O $@ http://closure-compiler.googlecode.com/files/compiler-latest.zip
	touch $@

.PRECIOUS: .build/examples/%.json
.build/examples/%.json: buildtools/example.json
	mkdir -p $(dir $@)
	sed 's/{{example}}/$*/' $< > $@

$(EXTERNS_ANGULAR):
	mkdir -p $(dir $@)
	wget -O $@ https://raw.githubusercontent.com/google/closure-compiler/master/contrib/externs/angular-1.4.js
	touch $@

$(EXTERNS_ANGULAR_Q):
	mkdir -p $(dir $@)
	wget -O $@ https://raw.githubusercontent.com/google/closure-compiler/master/contrib/externs/angular-1.4-q_templated.js
	touch $@

$(EXTERNS_ANGULAR_HTTP_PROMISE):
	mkdir -p $(dir $@)
	wget -O $@ https://raw.githubusercontent.com/google/closure-compiler/master/contrib/externs/angular-1.4-http-promise_templated.js
	touch $@

$(EXTERNS_JQUERY):
	mkdir -p $(dir $@)
	wget -O $@ https://raw.githubusercontent.com/google/closure-compiler/master/contrib/externs/jquery-1.9.js
	touch $@

.build/python-venv:
	mkdir -p .build
	virtualenv --no-site-packages $@

.build/python-venv/bin/gjslint: .build/python-venv
	.build/python-venv/bin/pip install "http://closure-linter.googlecode.com/files/closure_linter-latest.tar.gz"
	touch $@

.build/python-venv/bin/mako-render: .build/python-venv
	.build/python-venv/bin/pip install "Mako==1.0.0" "htmlmin==0.1.10"
	touch $@

.build/beautifulsoup4.timestamp: .build/python-venv
	.build/python-venv/bin/pip install "beautifulsoup4==4.3.2"
	touch $@

.build/closure-library:
	mkdir -p .build
	git clone http://github.com/google/closure-library/ $@

.build/ol-deps.js: .build/python-venv
	.build/python-venv/bin/python node_modules/ngeo/buildtools/closure/depswriter.py \
		--root_with_prefix="node_modules/openlayers/src ../../../../../../../../openlayers/src" \
		--root_with_prefix="node_modules/openlayers/build/ol.ext ../../../../../../../../openlayers/build/ol.ext" \
		--output_file=$@

.build/ngeo-deps.js: .build/python-venv
	.build/python-venv/bin/python node_modules/ngeo/buildtools/closure/depswriter.py \
		--root_with_prefix="src ../../../../../../../../../src" --output_file=$@

.build/jsdocOl3.js: jsdoc/get-ol3-doc-ref.js .build/node_modules.timestamp
	node $< > $@

.build/examples-hosted/apidoc: .build/node_modules.timestamp jsdoc.json .build/jsdocOl3.js $(SRC_JS_FILES)
	rm -rf $@
	./node_modules/.bin/jsdoc -c jsdoc/config.json --destination $@

contribs/gmf/apps/mobile/build/build.js: contribs/gmf/apps/mobile/build.json \
		$(EXTERNS_FILES) \
		$(GMF_APPS_MOBILE_JS_FILES) \
		.build/node_modules.timestamp
	mkdir -p $(dir $@)
	./node_modules/openlayers/node_modules/.bin/closure-util build $< $@

contribs/gmf/apps/mobile/build/build.css: %/build/build.css: $(GMF_APPS_MOBILE_LESS_FILES) \
		.build/node_modules.timestamp
	mkdir -p $(dir $@)
	./node_modules/.bin/lessc $*/less/main.less $@ --autoprefix

.PHONY: clean
clean:
	rm -f .build/*.check.timestamp
	rm -f .build/examples/*.js
	rm -f .build/gjslint.timestamp
	rm -f .build/jshint.timestamp
	rm -f .build/ol-deps.js
	rm -f .build/ngeo-deps.js
	rm -f .build/info.json
	rm -f dist/*
	rm -f $(EXTERNS_FILES)
	rm -rf .build/examples-hosted
	rm -rf .build/contribs
	rm -rf contribs/gmf/apps/mobile/build

.PHONY: cleanall
cleanall: clean
	rm -rf .build
	rm -rf dist
	rm -rf node_modules
