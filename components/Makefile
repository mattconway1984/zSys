COMPONENTS=$(patsubst %/,%,$(wildcard */)) 

.PHONY: $(COMPONENTS) recurse

$(MAKECMDGOALS) recurse: $(COMPONENTS)

$(COMPONENTS):
	@exec $(MAKE) -C $@ $(MAKECMDGOALS)

