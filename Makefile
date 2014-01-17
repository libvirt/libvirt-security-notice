
XML_NOTICES = $(wildcard notices/*/*.xml)

TEXT_NOTICES = $(XML_NOTICES:notices/%.xml=build/%.txt)
HTML_NOTICES = $(XML_NOTICES:notices/%.xml=build/%.html)
RAW_NOTICES = $(XML_NOTICES:notices/%.xml=build/%.xml)

all: $(TEXT_NOTICES) $(HTML_NOTICES) $(RAW_NOTICES) build/index.xml build/index.html

build/index.xml: $(XML_NOTICES) scripts/lsn2index
	mkdir -p `dirname $@`
	./scripts/lsn2index $(XML_NOTICES) > $@

build/index.html: build/index.xml templates/lsn2indexhtml.xsl
	./scripts/lsn2indexhtml $< > $@

build/%.txt: notices/%.xml templates/lsn2text.xsl
	mkdir -p `dirname $@`
	./scripts/lsn2text $< > $@

build/%.html: notices/%.xml templates/lsn2html.xsl
	mkdir -p `dirname $@`
	./scripts/lsn2html $< > $@

build/%.xml: notices/%.xml
	mkdir -p `dirname $@`
	cp $< $@

clean:
	rm -rf build/
