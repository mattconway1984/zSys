# All rules used by the zsys buildsystem are defined in this file. There should
# be no rules (to build or generate anything) defined outside of this file.


ifdef ZSYS_ROOT
include ${ZSYS_ROOT}/buildsys/common/tools.mk
include ${ZSYS_ROOT}/buildsys/common/globals.mk
endif


.DEFAULT_GOAL := all


#
# Make does not provide a recursive wildcard function; this works:
#
rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))

#
# Function to setup zSys buildsystem variables used to make the requested
# target
# 
# $(1) the name of the target
# $(2) the type of the target, either:
# 		application (TODO)
# 		component
# 		library
# 		test
# 
define SETUP_MAKE_VARS_TEMPLATE
$(1)_PATH = NOT_SET
ifeq "$(2)" "component"
$(1)_PATH = ${ZSYS_ROOT}/components/$(1)
$(1)_BUILD_PATH = $$(ZSYS_BUILD_ROOT)/artifacts/components/$(1)
else ifeq "$(2)" "test"
$(1)_BUILD_PATH = $$(ZSYS_BUILD_ROOT)/artifacts/tests/$(1)
ifdef $(1)_TESTING
ifneq ($$(wildcard ${ZSYS_ROOT}/components/$$($(1)_TESTING)/.),)
$(1)_TESTING_BUILD_PATH = $$(ZSYS_BUILD_ROOT)/artifacts/components/$$($(1)_TESTING)
$(1)_PATH = ${ZSYS_ROOT}/components/$$($(1)_TESTING)
else ifneq ($$(wildcard ${ZSYS_ROOT}/libraries/$$($(1)_TESTING)/.),)
$(1)_TESTING_BUILD_PATH = $$(ZSYS_BUILD_ROOT)/artifacts/libraries/$$($(1)_TESTING)
$(1)_PATH = ${ZSYS_ROOT}/libraries/$$($(1)_TESTING)
endif
endif
else ifeq "$(2)" "library"
$(1)_PATH = ${ZSYS_ROOT}/libraries/$(1)
$(1)_BUILD_PATH = $$(ZSYS_BUILD_ROOT)/artifacts/libraries/$(1)
endif
$(1)_SRCS_PATH = $$($(1)_PATH)/src
$(1)_INCS_PATH = $$($(1)_PATH)/inc
$(1)_TEST_PATH = $$($(1)_PATH)/test
endef

#
# Template used to create the build directories required to make the requested
# target
#
# $(1) the name of the target
#
define MKDIR_BUILD_DIRECTORIES_TEMPLATE
$$($(1)_BUILD_PATH):
	$(MKDIR) $$($(1)_BUILD_PATH)
$(1)_make_dirs: | $$($(1)_BUILD_PATH) 
MAKEDIRS+=$(1)_make_dirs
endef

#
# Template used to generate a rule for each dependency so that the zSys
# buildsystem knows how to recursively build each dependency.
#
define GENERATE_MAKE_DEPEND_TEMPLATE
ifeq "$$(findstring $(2),$$(ZSYS_ALL_COMPONENTS))" "$(2)"
$(1)_MAKE_$(2)_CMD = $(MAKE) build -C ${ZSYS_ROOT}/components/$(2)
else ifeq "$$(findstring $(2),$$(ZSYS_ALL_LIBRARIES))" "$(2)"
$(1)_MAKE_$(2)_CMD = $(MAKE) build -C ${ZSYS_ROOT}/libraries/$(2)
endif
ifdef $(1)_MAKE_$(2)_CMD
$(1)_make_depend_$(2):
	$$($(1)_MAKE_$(2)_CMD)
else
$(1)_make_depend_$(2): ;
endif
$(1)_make_all_depends += $(1)_make_depend_$(2)
endef

#
# Template used to generate a rule that has prequesite(s) for each of the 
# dependencies so the zSys buildsystem knows which dependencies are required
# to be built
#
define GENERATE_BUILD_DEPENDS_TEMPLATE
ifdef $(1)_DEPENDS
$(foreach d, $($(1)_DEPENDS), $(eval $(call GENERATE_MAKE_DEPEND_TEMPLATE,$(1),$d)))
$(1)_make_depends: $$($(1)_make_all_depends)
else
$(1)_make_depends: ;
endif
ifeq "$(2)" "component"
MAKE_COMPONENT_DEPENDS+=$(1)_make_depends
else ifeq "$(2)" "test"
MAKE_TEST_DEPENDS+=$(1)_make_depends
endif
endef

#
# Template used to generate a rule that tells the zSys buildsystem how to 
# generate the UNITY unit test runner (if it is required)
#
#  $1 is the name of the target executable
#
define GENERATE_TEST_RUNNER_TEMPLATE
ifdef $(1)_UNITY
$(1)_UNITY_TEST_RUNNER_HEADER = $$(patsubst %.c,%.h,$$($(1)_UNITY))
$(1)_UNITY_TEST_RUNNER_SOURCE = $$(patsubst %.c,%_runner.c,$$($(1)_UNITY))
$(1)_SOURCES := $$($(1)_UNITY_TEST_RUNNER_SOURCE) $$($(1)_SOURCES)
$$($(1)_UNITY_TEST_RUNNER_SOURCE): 
	$(RUBY) \
		$(UNITY_GENERATE_TEST_RUNNER) \
		$$($(1)_PATH)/$$($(1)_UNITY) \
		$$($(1)_PATH)/$$($(1)_UNITY_TEST_RUNNER_SOURCE) \
		--header_file="$$($(1)_PATH)/$$($(1)_UNITY_TEST_RUNNER_HEADER)"
endif
endef

#
# Template used to generate a rule to tell the zSys buildsystem how to generate
# a mock source/header (using CMOCK) for a public API
#
# $(1) Is the name of the target (test exe)
# $(2) Is the name of the file to be mocked (without extension)
#
define GENERATE_CMOCK_FILES_TEMPLATE
GEN_SOURCE = $$(patsubst %,test/$(CMOCK_PREFIX)%.c,$(2))
GEN_HEADER = $$(patsubst %,test/$(CMOCK_PREFIX)%.h,$(2)) 
$(1)_CMOCK_SOURCES := $$($(1)_CMOCK_SOURCES) $$(GEN_SOURCE) 
$(1)_CMOCK_HEADERS := $$($(1)_CMOCK_HEADERS) $$(GEN_HEADER)
$$(GEN_SOURCE):
	$(RUBY) \
		$(CMOCK_GENERATE_MOCK) \
		--input $(ZSYS_SHARED_INCS_PATH)/$(2).h \
	    --output $$($(1)_TEST_PATH) \
		--prefix $(CMOCK_PREFIX) 
$$(GEN_HEADER):
	$(RUBY) \
		$(CMOCK_GENERATE_MOCK) \
		--input $(ZSYS_SHARED_INCS_PATH)/include/$(2).h \
	    --output $$($(1)_TEST_PATH) \
		--prefix $(CMOCK_PREFIX) 
endef

#
# Template used to generate a rule for each mock that is specified in the 
# <target>_CMOCK list which tells the zSys buildsystem how to generate the
# required mocks using CMOCK.
#
# The headers that can be mocked live here:
#   <ZSYS>/build/include
#
# CMOCK will put the auto generated files here:
#   $(1)_TEST_PATH/generated[.h|.c]
#
#  $(1) is the name of the target executable
#
define GENERATE_CMOCK_TEMPLATE
ifdef $(1)_CMOCK
$(foreach m, $$($(1)_CMOCK), $(eval $(call GENERATE_CMOCK_FILES_TEMPLATE,$(1),$(m))))
$(1)_SOURCES := $$($(1)_CMOCK_SOURCES) $$($(1)_SOURCES)
endif
endef

#
# Template used to generate a rule that tells the zSys buildsystem how to build
# each object file depending on the listed sources, in the Makefile variable
# <target>_SOURCES
#
define BUILD_OBJECTS_TEMPLATE
$(1)_OBJECTS = $(patsubst $(2)/%,$$($(1)_BUILD_PATH)/%.o,$($(1)_SOURCES))
$$($(1)_BUILD_PATH)/%.c.o: $(2)/%.c 
	$(CC) \
		-c $$< \
		$(CFLAGS) \
		-I$$(ZSYS_SHARED_INCS_PATH) \
		-I$($(1)_SRCS_PATH) \
		-I$($(1)_INCS_PATH) \
		-o $$@ 
endef

#
# Template used to generate a rule that tells the zSys buildsystem how to build
# a shared object
#
define BUILD_SHARED_OBJECT_TEMPLATE
$(1)_BUILD_ARTIFACTS += $$(filter-out $$($(1)_INCS_PATH),$$(patsubst $$($(1)_INCS_PATH)/%,$$(ZSYS_SHARED_INCS_PATH)/%,$(call rwildcard,$($(1)_INCS_PATH),*)))
$(1)_BUILD_ARTIFACTS += $$(ZSYS_SHARED_LIBS_PATH)/lib$(1).so
$$(ZSYS_SHARED_LIBS_PATH)/lib$(1).so: $$($(1)_OBJECTS)
	$(CC) \
		$(LFLAGS) \
		$(LFLAGS_SO) \
		$(LFLAGS_COV) \
		$$($(1)_OBJECTS) \
		-o $$(ZSYS_SHARED_LIBS_PATH)/lib$(1).so 
	$(CPFILE) $$($(1)_INCS_PATH)/* $$(ZSYS_SHARED_INCS_PATH)
$(1): $$(ZSYS_SHARED_LIBS_PATH)/lib$(1).so 
endef

#
# Template used to generate a rule that tells the zSys buildsystem how to build
# a test runner binary
#
define BUILD_TEST_RUNNER_TEMPLATE
$(1)_SO_DEPENDS = $$(patsubst %,$$(ZSYS_SHARED_LIBS_PATH)/lib%.so,$$($(1)_DEPENDS))
$(1)_LINK_DEPENDS = $$(patsubst %,-l%,$$($(1)_DEPENDS))
ifdef $(1)_TESTING
$(1)_LINK_DEPENDS += $$(patsubst %,-l%,$$($(1)_TESTING))
endif
$(1)_BUILD_ARTIFACTS += $$($(1)_BUILD_PATH)/$(1)_runner
$$($(1)_BUILD_PATH)/$(1)_runner: $$($(1)_SO_DEPENDS) $$($(1)_OBJECTS)
	$(CC) \
		$$($(1)_OBJECTS) \
		$$(CFLAGS) \
		-I. \
		-I$$(ZSYS_SHARED_INCS_PATH) \
		-L$$(ZSYS_SHARED_LIBS_PATH) \
		$$($(1)_LINK_DEPENDS) \
		-o $$@ 
ifdef $(1)_UNITY_TEST_RUNNER_SOURCE
	@echo "==================================================================="
	@echo "Removing *temporary* auto generated sources for '$(1)'"
	@echo "==================================================================="
else ifdef $(1)_CMOCK_SOURCES
	@echo "==================================================================="
	@echo "Removing *temporary* auto generated sources for '$(1)'"
	@echo "==================================================================="
endif

ifdef $(1)_UNITY_TEST_RUNNER_SOURCE
	$(RMDIR) $$($(1)_UNITY_TEST_RUNNER_SOURCE)
	$(RMDIR) $$($(1)_UNITY_TEST_RUNNER_HEADER)
endif
ifdef $(1)_CMOCK_SOURCES
	$(RMDIR) $$($(1)_CMOCK_SOURCES)
	$(RMDIR) $$($(1)_CMOCK_HEADERS)
endif
endef

#
# Template used to generate a rule that tells the zSys buildsystem how to run
# the built test runner binary
#
define RUN_TEST_RUNNER_TEMPLATE 
ifdef $(1)_TESTING
$(1)_GCOV_FILES = $$(patsubst %,$$($(1)_TESTING_BUILD_PATH)/%.gcno,$$(patsubst src/%,%,$$($$($(1)_TESTING)_SOURCES)))
endif
$(1): $$($(1)_BUILD_PATH)/$(1)_runner 
	@echo "==================================================================="
	@echo "RUNNING TEST SUITE: $$(@)"
	@echo "==================================================================="
	$$($(1)_BUILD_PATH)/$(1)_runner
ifdef $(1)_TESTING
	$(GCOV) $$($(1)_GCOV_FILES)
endif
endef

#
# Tempate used to generate a rule to tell the zSys buildsystem how to modify
# the doxygen configuration file so that docs will be generated for the target
#
define CONFIGURE_DOXYGEN_TEMPLATE
$(1)_make_docs:
	echo "INPUT += $$($(1)_SRCS_PATH)" >> $$(ZSYS_DOXYGEN_CONFIG_FILE)
	echo "INPUT += $$($(1)_INCS_PATH)" >> $$(ZSYS_DOXYGEN_CONFIG_FILE)
MAKE_DOCS+=$(1)_make_docs
endef

#
# Template used to generate a rule to tell the zSys buildsystem what artifacts
# to clean up for the target
#
define CLEANUP_TEMPLATE
$(1)_BUILD_ARTIFACTS += $$($(1)_BUILD_PATH)/*.gcno 
$(1)_BUILD_ARTIFACTS += $$($(1)_BUILD_PATH)/*.gcda 
$(1)_BUILD_ARTIFACTS += $$($(1)_BUILD_PATH)/*.so
$(1)_BUILD_ARTIFACTS += $$($(1)_BUILD_PATH)/*.o
$(1)_BUILD_ARTIFACTS += $$($(1)_BUILD_PATH)/*.c.o
$(1)_clean:
	$(RMDIR) $$($(1)_BUILD_ARTIFACTS)
CLEANUP+=$(1)_clean
endef

$(eval $(call MAKE_ZSYS_BUILD_DIRS))

$(foreach c, $(COMPONENTS), $(eval $(call SETUP_MAKE_VARS_TEMPLATE,$c,component)))
$(foreach c, $(COMPONENTS), $(eval $(call MKDIR_BUILD_DIRECTORIES_TEMPLATE,$c)))
$(foreach c, $(COMPONENTS), $(eval $(call GENERATE_BUILD_DEPENDS_TEMPLATE,$c,component)))
$(foreach c, $(COMPONENTS), $(eval $(call BUILD_OBJECTS_TEMPLATE,$c,src)))
$(foreach c, $(COMPONENTS), $(eval $(call BUILD_SHARED_OBJECT_TEMPLATE,$c)))
$(foreach c, $(COMPONENTS), $(eval $(call CONFIGURE_DOXYGEN_TEMPLATE,$c)))
$(foreach c, $(COMPONENTS), $(eval $(call CLEANUP_TEMPLATE,$c)))

$(foreach l, $(LIBRARIES), $(eval $(call SETUP_MAKE_VARS_TEMPLATE,$l,library)))
$(foreach l, $(LIBRARIES), $(eval $(call MKDIR_BUILD_DIRECTORIES_TEMPLATE,$l)))
$(foreach l, $(LIBRARIES), $(eval $(call GENERATE_BUILD_DEPENDS_TEMPLATE,$l,library)))
$(foreach l, $(LIBRARIES), $(eval $(call BUILD_OBJECTS_TEMPLATE,$l,src)))
$(foreach l, $(LIBRARIES), $(eval $(call BUILD_SHARED_OBJECT_TEMPLATE,$l)))
$(foreach l, $(LIBRARIES), $(eval $(call CLEANUP_TEMPLATE,$l)))

$(foreach t, $(TESTS), $(eval $(call SETUP_MAKE_VARS_TEMPLATE,$t,test)))
$(foreach t, $(TESTS), $(eval $(call MKDIR_BUILD_DIRECTORIES_TEMPLATE,$t)))
$(foreach t, $(TESTS), $(eval $(call GENERATE_BUILD_DEPENDS_TEMPLATE,$t,test)))
$(foreach t, $(TESTS), $(eval $(call GENERATE_TEST_RUNNER_TEMPLATE,$t)))
$(foreach t, $(TESTS), $(eval $(call GENERATE_CMOCK_TEMPLATE,$t)))
$(foreach t, $(TESTS), $(eval $(call BUILD_OBJECTS_TEMPLATE,$t,test)))
$(foreach t, $(TESTS), $(eval $(call BUILD_TEST_RUNNER_TEMPLATE,$t)))
$(foreach t, $(TESTS), $(eval $(call RUN_TEST_RUNNER_TEMPLATE,$t)))
$(foreach t, $(TESTS), $(eval $(call CLEANUP_TEMPLATE,$t)))

#
# A rule to ensure the ZSYS environment variables have been set, cannot do 
# anything without these being set first.
#
.PHONY env-check:
env-check:
ifndef ZSYS_ROOT
	$(error You must setup zsys environment: source buildsys/common/env.sh)
endif
ifndef ZSYS_DISTRIBUTION
	$(error You must setup zsys environment: source buildsys/common/env.sh)
endif
ifndef ZSYS_TARGET
	$(error You must setup zsys environment: source buildsys/common/env.sh)
endif

#
# A rule to reset the doxy configuration file. During a build the doxy conf
# file is modified so it knows which input files to generate docs for
#
clean-doxy-conf:
	$(CPFILE) $(ZSYS_DOXYGEN_CONFIG_BACKUP) $(ZSYS_DOXYGEN_CONFIG_FILE)

#
# A rule to build the directory where the shared libraries will be built into
#
$(ZSYS_SHARED_LIBS_PATH):
	$(MKDIR) $(ZSYS_SHARED_LIBS_PATH)

#
# A rule to build the directory where the shared binaries will be built into
#
$(ZSYS_SHARED_BINS_PATH):
	$(MKDIR) $(ZSYS_SHARED_BINS_PATH)

#
# A rule to build the directory where the shared headers (public APIs) will
# be copied
#
$(ZSYS_SHARED_INCS_PATH):
	$(MKDIR) $(ZSYS_SHARED_INCS_PATH)

#
# A rule to build the directory where the doxygen output will be generated
#
$(ZSYS_DOXYGEN_PATH):
	$(MKDIR) $(ZSYS_DOXYGEN_PATH)

#
# A rule to build the ZSYS build directories (ignoring directory timestamps)
#
build-dirs: $(MAKEDIRS) | $(ZSYS_SHARED_INCS_PATH) $(ZSYS_SHARED_BIN_PATH) $(ZSYS_SHARED_LIBS_PATH) $(ZSYS_DOXYGEN_PATH)

#
# A rule to gather (and build) the dependencies required to build a component
#
depends: $(MAKE_COMPONENT_DEPENDS)

#
# A rule to gather (and build) the dependencies required to build a test runner
#
test-depends: $(MAKE_TEST_DEPENDS)

#
# A rule to build the defined list of COMPONENTS (includes code coverage)
#
build: build-dirs depends $(COMPONENTS) $(LIBRARIES) 

#
# TODO: This is just a thought.....
# A rule to build the defined list of COMPONENTS (stripped for release)
#
release: build-dirs depends $(COMPONENTS_REL) $(LIBRARIES_REL) 

#
# A rule to build and run the defined list of TESTS
#
test: build-dirs test-depends $(TESTS)
	@echo "==================================================================="
	@echo "TESTS COMPLETE!"
	@echo "==================================================================="

#
# A rule to run doxygen for the list of defined COMPONENTS
#
docs: build-dirs clean-doxy-conf $(MAKE_DOCS)
	echo "OUTPUT_DIRECTORY = $(ZSYS_DOXYGEN_PATH)" >> $(ZSYS_DOXYGEN_CONFIG_FILE)
	echo "STRIP_FROM_PATH = ${ZSYS_ROOT}/components" >> $(ZSYS_DOXYGEN_CONFIG_FILE)

	$(DOXYGEN) $(ZSYS_DOXYGEN_CONFIG_FILE)
	@echo "==================================================================="
	@echo "GENERATED DOCS: $(strip $(ZSYS_DOXYGEN_PATH))/html/index.html"
	@echo "==================================================================="


#
# A rule to cleanup all the build artifacts
#
clean: clean-doxy-conf $(CLEANUP)

#
# A rule to build everything, clean, build the test
#
.PHONY all:
all: env-check clean build-dirs depends test-depends build test 

