# DESCRIPTION:
#  Recursively enter each library and run the make command

LIBRARIES=$(patsubst %/,%,$(wildcard */)) 

.PHONY: $(LIBRARIES) recurse

$(MAKECMDGOALS) recurse: $(LIBRARIES)

$(LIBRARIES):
	@exec $(MAKE) -C $@ $(MAKECMDGOALS)

