
XML_NOTICES = $(wildcard notices/*/*.xml)

TEXT_NOTICES = $(XML_NOTICES:%.xml=%.txt)

all: text

text: $(TEXT_NOTICES)


%.txt: %.xml
	perl scripts/lsn2text $< > $@

clean:
	rm -f $(TEXT_NOTICES)
