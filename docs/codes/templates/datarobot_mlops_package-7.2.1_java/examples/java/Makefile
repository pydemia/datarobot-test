
SUBDIRS := CodeGenExample PredictionsData SampleCode SingleCommandExample SparkExample SparkUtilsExample

.PHONY: $(SUBDIRS) build clean

build: $(SUBDIRS)

$(SUBDIRS):
	@echo "Building $@"
	$(MAKE) -C $@

clean:
	for d in $(SUBDIRS); do $(MAKE) -C $$d clean; done
