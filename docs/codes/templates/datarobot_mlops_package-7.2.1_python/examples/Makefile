
SUBDIRS := java

.PHONY: $(SUBDIRS) build clean

build: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@

clean:
	for d in $(SUBDIRS); do $(MAKE) -C $$d clean; done

