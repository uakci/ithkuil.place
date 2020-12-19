TARGET  ?= target
WWW     := $(TARGET)/www

.PHONY: docker all allish clean graft nildb sitemap $(WWW)/4/archive

all: | $(TARGET) $(WWW) allish sitemap
allish: graft nildb $(WWW)/4/archive $(WWW)/mirror $(WWW)/mirror-mod $(TARGET)/etc/nginx/nginx.conf

docker: all
	docker build -t ithkuil.place .

clean:
	rm -r $(TARGET)

$(TARGET):
	mkdir -p $@

$(WWW): www LICENSE
	cp -rvuT www $(WWW)
	cp -u LICENSE $(WWW)/LICENSE

$(TARGET)/etc/nginx/nginx.conf: src/nginx.conf
	install -D src/nginx.conf $@

graft: $(patsubst src/graft/%,$(WWW)/%,$(patsubst %.md,%.html,$(wildcard src/graft/*.md)))

$(WWW)/%.html: src/graft/%.md src/graft/graft.sh
	./src/graft/graft.sh $< $@

nildb: $(patsubst src/%,$(WWW)/%,$(patsubst %.yml,%.html,$(shell find src/4/docs/nildb -name '*.yml')))

$(WWW)/4/docs/nildb/%.html: src/4/docs/nildb/%.yml src/4/docs/freetnil/build/templates/category.html src/4/docs/freetnil/build/scripts/convert-one.sh
	mkdir -p $(basename -- $@)
	./src/4/docs/freetnil/build/scripts/convert-one.sh $< $@ ./src/4/docs/freetnil/build/templates/category.html >/dev/null

$(WWW)/mirror-mod: $(WWW)/mirror src/mirroring/modify.sh
	cd $(WWW) && $(PWD)/src/mirroring/modify.sh

$(WWW)/mirror: www/mirror/
	mkdir -p $@
	cp -rvuT www/mirror/ $@

$(WWW)/4/archive:
	mkdir -p $@
	cp -rvu www/4/archive/* $@
	cd $@ && $(PWD)/src/4/archive/archive.sh $(PWD)/src/4/archive/index.html.template

sitemap: $(WWW)/SITEMAP.html

$(WWW)/SITEMAP.html:
	mkdir -p $(WWW)
	tree -H "" . > $@
