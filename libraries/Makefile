LIBRARIES=$(patsubst %/,%,$(wildcard */)) 

.PHONY: $(LIBRARIES) recurse

$(MAKECMDGOALS) recurse: $(LIBRARIES)

$(LIBRARIES):
	@exec $(MAKE) -C $@ $(MAKECMDGOALS)

