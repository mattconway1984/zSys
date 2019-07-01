# DESCRIPTION:
#  Every rule used to build or generate targets is defined in this file. There
#  should be no rules (to build or generate anything) defined outside of this 
#  file.

# Include other zSys makefiles which setup variables used by this file
ifdef ZSYS_ROOT
include ${ZSYS_ROOT}/buildsys/common/tools.mk
include ${ZSYS_ROOT}/buildsys/common/globals.mk
endif

# Automatically build the "all" target if no target has been specified
.DEFAULT_GOAL := all

#
# As GNU Make does not provide a recursive wildcard function, this macro
# implements recursive wildcard:
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
define SETUP_MAKE_VARIABLES
$(1)_PATH = NOT_SET
$(1)_SRCS_PATH = $(1)_SRCS_PATH_NOT_SET 
$(1)_INCS_PATH = $(1)_INCS_PATH_NOT_SET
$(1)_TEST_PATH = $(1)_TEST_PATH_NOT_SET
ifeq "$(2)" "component"
ifdef $(1)_COMPONENT
$(1)_PATH = ${ZSYS_ROOT}/components/$$($(1)_COMPONENT)
$(1)_BUILD_PATH = $$(ZSYS_BUILD_ROOT)/artifacts/components/$$($(1)_COMPONENT)
else
$(1)_PATH = ${ZSYS_ROOT}/components/$(1)
$(1)_BUILD_PATH = $$(ZSYS_BUILD_ROOT)/artifacts/components/$(1)
endif
else ifeq "$(2)" "lib"
$(1)_PATH = ${ZSYS_ROOT}/libraries/$(1)
$(1)_BUILD_PATH = $$(ZSYS_BUILD_ROOT)/artifacts/libraries/$(1)
else ifeq "$(2)" "test"
$(1)_BUILD_PATH = $$(ZSYS_BUILD_ROOT)/artifacts/tests/$(1)
endif
ifdef $(1)_TESTING
$(1)_PATH = ${ZSYS_ROOT}/components/$$($(1)_TESTING)
$(1)_SRCS_PATH = $$($(1)_PATH)/src
$(1)_INCS_PATH = $$($(1)_PATH)/inc
$(1)_TEST_PATH = $$($(1)_PATH)/test
$(1)_TESTING_BUILD_PATH = $$(ZSYS_BUILD_ROOT)/artifacts/components/$$($(1)_TESTING)
else
$(1)_SRCS_PATH = $$($(1)_PATH)/src
$(1)_INCS_PATH = $$($(1)_PATH)/inc
$(1)_TEST_PATH = $$($(1)_PATH)/test
endif
endef


#
# Function to generate a rule to build a directory
#
define GENERATE_MKDIR_RULE_TEMPLATE
$(1):
	$(MKDIR) $$@
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
# Function to generate a rule for each dependency so that the zSys
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
# Function to generate a rule that has prequesite(s) for each of the 
# dependencies so the zSys buildsystem knows which dependencies are required
# to be built
#
# $(1) The name of the target to be built (<COMPONENT>, <TEST> or <LIBRARY>)
#
define GENERATE_BUILD_DEPENDS_TEMPLATE
$(1)_make_depends: ;
ifdef $(1)_DEPENDS
$(foreach d, $($(1)_DEPENDS), $(eval $(call GENERATE_MAKE_DEPEND_TEMPLATE,$(1),$d)))
endif
ifdef $(1)_TESTING
$(foreach c, $($(1)_TESTING), $(eval $(call GENERATE_MAKE_DEPEND_TEMPLATE,$(1),$c)))
endif
$(1)_make_depends: $$($(1)_make_all_depends)
ifeq "$(2)" "component"
MAKE_COMPONENT_DEPENDS+=$(1)_make_depends
else ifeq "$(2)" "test"
MAKE_TEST_DEPENDS+=$(1)_make_depends
else ifeq "$(2)" "library"
MAKE_LIBRARY_DEPENDS+=$(1)_make_depends
endif
endef

#
# Function to generate a rule that tells the zSys buildsystem how to 
# generate the UNITY unit test runner (if it is required)
#
# $(1) The name of the test target to be built
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
# Function to generate a rule to tell the zSys buildsystem how to generate
# a mock source/header (using CMOCK) for a public API
#
# $(1) The name of the test target to be built
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
# Function to generate a rule for each mock that is specified in the 
# <target>_CMOCK list which tells the zSys buildsystem how to generate the
# required mocks using CMOCK.
#
# The headers that can be mocked live here:
#   <ZSYS>/build/include
#
# CMOCK will put the auto generated files here:
#   $(1)_TEST_PATH/generated[.h|.c]
#
# $(1) The name of the test target to be built
#
define GENERATE_CMOCK_TEMPLATE
ifdef $(1)_CMOCK
$(foreach m, $$($(1)_CMOCK), $(eval $(call GENERATE_CMOCK_FILES_TEMPLATE,$(1),$(m))))
$(1)_SOURCES := $$($(1)_CMOCK_SOURCES) $$($(1)_SOURCES)
endif
endef

#
# Function used to generate rules that tell the zSys buildsystem how to make
# the required directories which will be used to put the built objects into
#
define MAKE_OBJECT_BUILD_DIRS_TEMPLATE
$(foreach d, $(sort $($(1)_OBJECT_DIRS)), $(eval $(call GENERATE_MKDIR_RULE_TEMPLATE,$(d))))
endef

#
# Function used to generate a rule that tells the zSys buildsystem how to build
# each object file depending on the listed sources, in the Makefile variable
# <target>_SOURCES
#
# $(1) The name of the target to be built (<COMPONENT>, <TEST> or <LIBRARY>)
# $(2) The name of the directory which contains the root path to the source
#      files used to build the target (either "src" or "test")
# $(3) If this is set to "component" then the object file will be created by
#      compiling the source file using strict CFLAGS/CXXFLAGS. Because each
#      <COMPONENT> is what we own it should be writing clean code. Tests are 
#      not deployed and don't require such "strict" compilation, and libraries
#      are third party, so do not require such strict flags (use of third party
#      libs should be kept to a minimum).
#
#
# The issue here is if we are pulling a source file in directly for a test, 
# the object is hard to build, it resides in:
#
# 	src/foo.cpp
#
# but the tests are building from
#
# 	test/xxxx
#
# which means the rule to depend on the source file is more difficult to 
# build (but not impossible)!
#
#
define BUILD_OBJECTS_TEMPLATE
$(1)_OBJECTS = $(patsubst $(2)/%,$$($(1)_BUILD_PATH)/%.o,$($(1)_SOURCES))
$(1)_OBJECT_DIRS = $(patsubst %,$$(dir %),$$($(1)_OBJECTS))
$(1)_LINK_DEPENDS = $$(patsubst %,-l%,$$($(1)_DEPENDS))
ifeq "$(3)" "component"
$(1)_CFLAGS_STRICT = $(CFLAGS_STRICT)
$(1)_CXXFLAGS_STRICT = $(CXXFLAGS_STRICT)
endif
$$($(1)_BUILD_PATH)/%.c.o: $(2)/%.c | $$($(1)_OBJECT_DIRS)
	@echo "building: $$@ from $$<"
	$(CC) \
		-c $$< \
		$(CFLAGS) \
		$$($(1)_CFLAGS_STRICT) \
		$$($(1)_SYMBOLS) \
		-I$$(ZSYS_SHARED_INCS_PATH) \
		-I$$($(1)_SRCS_PATH) \
		-I$$($(1)_INCS_PATH) \
		-L$$(ZSYS_SHARED_LIBS_PATH) \
		$$($(1)_LINK_DEPENDS) \
		-o $$@ 
# Generate a "pattern rule" to build objects from CPP sources:
$$($(1)_BUILD_PATH)/%.cpp.o: $(2)/%.cpp | $$($(1)_OBJECT_DIRS)
	@echo "building: $$@ from $$<"
	$(CXX) \
		-c $$< \
		$(CXXFLAGS) \
		$$($(1)_CXXFLAGS_STRICT) \
		$$($(1)_SYMBOLS) \
		-I$$(ZSYS_SHARED_INCS_PATH) \
		-I$$($(1)_SRCS_PATH) \
		-I$$($(1)_INCS_PATH) \
		-L$$(ZSYS_SHARED_LIBS_PATH) \
		$$($(1)_LINK_DEPENDS) \
		-o $$@ 
# Generate a "pattern rule" to build objects from CC sources:
$$($(1)_BUILD_PATH)/%.cc.o: $(2)/%.cc | $$($(1)_OBJECT_DIRS)
	@echo "building: $$@ from $$<"
	$(CXX) \
		-c $$< \
		$(CXXFLAGS) \
		$$($(1)_CXXFLAGS_STRICT) \
		$$($(1)_SYMBOLS) \
		-I$$(ZSYS_SHARED_INCS_PATH) \
		-I$$($(1)_SRCS_PATH) \
		-I$$($(1)_INCS_PATH) \
		-L$$(ZSYS_SHARED_LIBS_PATH) \
		$$($(1)_LINK_DEPENDS) \
		-o $$@ 
endef

#
# Function to generate rules that tells the zSys buildsystem how to build each
# an object file for each of the sources that require testing.
# This allows developers to write a test suite that tests partial functionality
# of a component by linking against objects rather than liking against the 
# fully built component (shared object).
#
# $(1) The name of the test target to be built
# $(2) The name of the source from which to build the object
#
define BUILD_TESTING_OBJECT_TEMPLATE
$(1)_$(2)_OBJECT = $$(patsubst src/%,$$($(1)_BUILD_PATH)/%.o,$(2))
$(1)_$(2)_PATH = $(patsubst %,$$(dir %),$$($(1)_$(2)_OBJECT))
$(1)_TESTING_OBJECTS += $$($(1)_$(2)_OBJECT) 
$(1)_OBJECTS += $$($(1)_$(2)_OBJECT)
$$($(1)_$(2)_OBJECT): $(2) | $$($(1)_$(2)_PATH) 
	@echo "building: $$@ from $$<"
	$(CXX) \
		-c $$< \
		$(CXXFLAGS) \
		$$($(1)_CXXFLAGS_STRICT) \
		$$($(1)_SYMBOLS) \
		-I$$(ZSYS_SHARED_INCS_PATH) \
		-I$$($(1)_SRCS_PATH) \
		-I$$($(1)_INCS_PATH) \
		-L$$(ZSYS_SHARED_LIBS_PATH) \
		$$($(1)_LINK_DEPENDS) \
		-o $$@ 
endef

define BUILD_TESTING_OBJECTS_TEMPLATE
ifdef $(1)_TESTING
ifdef $(1)_TESTING_SOURCES
$(foreach o, $$($(1)_TESTING_SOURCES), $(eval $(call BUILD_TESTING_OBJECT_TEMPLATE,$1,$o)))
endif
endif
endef

#
# Function to generate a rule that tells the zSys buildsystem how to build
# a shared object
#
# $(1) The name of the target to be built (<COMPONENT> or <LIBRARY>)
#
define BUILD_SHARED_OBJECT_TEMPLATE
$(1)_BUILD_ARTIFACTS += $$(filter-out $$($(1)_INCS_PATH),$$(patsubst $$($(1)_INCS_PATH)/%,$$(ZSYS_SHARED_INCS_PATH)/%,$(call rwildcard,$($(1)_INCS_PATH),*.*)))
$(1)_BUILD_ARTIFACTS += $$(ZSYS_SHARED_LIBS_PATH)/lib$(1).so
$(1)_SO_DEPENDS = $$(patsubst %,$$(ZSYS_SHARED_LIBS_PATH)/lib%.so,$$($(1)_DEPENDS))
$$(ZSYS_SHARED_LIBS_PATH)/lib$(1).so: $$($(1)_OBJECTS)
ifneq "$$(findstring .c.o,$$($(1)_OBJECTS))" ""
	$(CC) \
		$(LFLAGS) \
		$(LFLAGS_SO) \
		$(LFLAGS_COV) \
		$$($(1)_SYMBOLS) \
		$$($(1)_OBJECTS) \
		-L$$(ZSYS_SHARED_LIBS_PATH) \
		$$($(1)_LINK_DEPENDS) \
		-o $$(ZSYS_SHARED_LIBS_PATH)/lib$(1).so 
else
	$(CXX) \
		$(LXXFLAGS) \
		$(LXXFLAGS_SO) \
		$(LXXFLAGS_COV) \
		$$($(1)_SYMBOLS) \
		$$($(1)_OBJECTS) \
		-L$$(ZSYS_SHARED_LIBS_PATH) \
		$$($(1)_LINK_DEPENDS) \
		-o $$(ZSYS_SHARED_LIBS_PATH)/lib$(1).so 
endif
	$(CPFILE) $$($(1)_INCS_PATH)/* $$(ZSYS_SHARED_INCS_PATH)
$(1): $$(ZSYS_SHARED_LIBS_PATH)/lib$(1).so 
endef

#
# Function to generate a rule that tells the zSys buildsystem how to build
# a test runner binary
#
# $(1) The name of the test target to be built
#
define BUILD_TEST_RUNNER_TEMPLATE
$(1)_SO_DEPENDS = $$(patsubst %,$$(ZSYS_SHARED_LIBS_PATH)/lib%.so,$$($(1)_DEPENDS))
ifneq "$$(findstring .c.o,$$($(1)_OBJECTS))" ""
LDD=$$(CC)
LDDFLAGS=$$(LFLAGS)
LDDFLAGS_COV=$$(LFLAGS_COV)
LDDFLAGS_SO=$$(LFLAGS_SO)
else
LDD=$$(CXX)
LDDFLAGS=$$(LXXFLAGS)
LDDFLAGS_COV=$$(LXXFLAGS_COV)
LDDFLAGS_SO=$$(LXXFLAGS_SO)
endif
$(1)_BUILD_ARTIFACTS += $$($(1)_BUILD_PATH)/$(1)_runner
$$($(1)_BUILD_PATH)/$(1)_runner: $$($(1)_SO_DEPENDS) $$($(1)_OBJECTS)
	@echo "linking: $$@"
	$$(LDD) \
		$$(LDDFLAGS) \
		$$(LDDFLAGS_COV) \
		-I$$($(1)_INCS_PATH) \
		-I$$($(1)_SRCS_PATH) \
		-I$$(ZSYS_SHARED_INCS_PATH) \
		-L$$(ZSYS_SHARED_LIBS_PATH) \
		$$($(1)_LINK_DEPENDS) \
		$$($(1)_OBJECTS) \
		$$($(1)_SYMBOLS) \
		-o $$@ 
ifdef $(1)_UNITY
	@echo "==================================================================="
	@echo "Removing *temporary* auto generated sources for '$(1)'"
	@echo "==================================================================="
else ifdef $(1)_CMOCK
	@echo "==================================================================="
	@echo "Removing *temporary* auto generated sources for '$(1)'"
	@echo "==================================================================="
endif
ifdef $(1)_UNITY
	$(RMDIR) $$($(1)_UNITY_TEST_RUNNER_SOURCE)
	$(RMDIR) $$($(1)_UNITY_TEST_RUNNER_HEADER)
endif
ifdef $(1)_CMOCK
	$(RMDIR) $$($(1)_CMOCK_SOURCES)
	$(RMDIR) $$($(1)_CMOCK_HEADERS)
endif
endef

#
# Function used to generate a rule that tells the zSys buildsystem how to run
# the built test runner binary
#
# $(1) The name of the test target to execute 
#
define RUN_TEST_RUNNER_TEMPLATE 
$(1): $$($(1)_BUILD_PATH)/$(1)_runner 
	@echo "==================================================================="
	@echo "RUNNING TEST SUITE: $$(@)"
	@echo "==================================================================="
	$$($(1)_BUILD_PATH)/$(1)_runner
endef

#
# Function used to generate a rule that tells the zSys buildsystem how to run
# the unittest code coverage for the component
# If the test code was testing code as objects rather than linking against the
# full shared library, then only run gcov on the files explicitly defined as
# being tested by that test (as others will not exist).
#
# $(1) The name of the target which to run code coverage for.
#
define RUN_COVERAGE_TEMPATE
ifdef $(1)_TESTING
ifdef $(1)_TESTING_SOURCES
$(1)_GCOV_FILES = $$(patsubst src/%,$$($(1)_BUILD_PATH)/%.gcno,$$($(1)_TESTING_SOURCES))
else
# TODO: the problem with this is that the files here are not the ones that were
# executed, so need to think about this a bit more, but it gives a general
# idea on how to resolve this.... Maybe need to copy the gcov files to a 
# central place?
$(1)_GCOV_FILES = $$(patsubst %,$$($(1)_TESTING_BUILD_PATH)/%.gcno,$$(patsubst src/%,%,$$($$($(1)_TESTING)_SOURCES)))
endif
endif
ifdef $(1)_GCOV_FILES
$(1)_coverage:
	@echo "==================================================================="
	@echo "CODE COVERAGE REPORT FOR: $(1)"
	@echo "==================================================================="
	$(GCOV) $$($(1)_GCOV_FILES)
RUN_COVERAGE+=$(1)_coverage
endif
endef

#
# Function to generate a rule to tell the zSys buildsystem how to modify
# the doxygen configuration file so that docs will be generated for the target
#
# $(1) The name of the component for which doxygen shall generate docs
#
define CONFIGURE_DOXYGEN_TEMPLATE
$(1)_make_docs:
	echo "INPUT += $$($(1)_SRCS_PATH)" >> $$(ZSYS_DOXYGEN_CONFIG_FILE)
	echo "INPUT += $$($(1)_INCS_PATH)" >> $$(ZSYS_DOXYGEN_CONFIG_FILE)
MAKE_DOCS+=$(1)_make_docs
endef

#
# Function to generate a rule to tell the zSys buildsystem what artifacts
# to clean up for the target
#
# $(1) The name of the target to be built (<COMPONENT>, <TEST> or <LIBRARY>)
#
# TODO Cleanup should also remove any "installed" public headers for the
# library or component.
#
define CLEANUP_TEMPLATE
$(1)_BUILD_ARTIFACTS += $$($(1)_BUILD_PATH)/*.gcno 
$(1)_BUILD_ARTIFACTS += $$($(1)_BUILD_PATH)/*.gcda 
$(1)_BUILD_ARTIFACTS += $$($(1)_BUILD_PATH)/*.c.o
$(1)_BUILD_ARTIFACTS += $$($(1)_BUILD_PATH)/*.cc.o
$(1)_BUILD_ARTIFACTS += $$($(1)_BUILD_PATH)/*.cpp.o
$(1)_clean:
	$(RMDIR) $$($(1)_BUILD_ARTIFACTS)
CLEANUP+=$(1)_clean
endef

# For each of the components defined in the COMPONENTS variable of the Makefile, 
# generate the rules required to make the requested target:
$(foreach c, $(COMPONENTS), $(eval $(call SETUP_MAKE_VARIABLES,$c,component)))
$(foreach c, $(COMPONENTS), $(eval $(call MKDIR_BUILD_DIRECTORIES_TEMPLATE,$c)))
$(foreach c, $(COMPONENTS), $(eval $(call GENERATE_BUILD_DEPENDS_TEMPLATE,$c,component)))
$(foreach c, $(COMPONENTS), $(eval $(call BUILD_OBJECTS_TEMPLATE,$c,src)))
$(foreach c, $(COMPONENTS), $(eval $(call MAKE_OBJECT_BUILD_DIRS_TEMPLATE,$c)))
$(foreach c, $(COMPONENTS), $(eval $(call BUILD_SHARED_OBJECT_TEMPLATE,$c)))
$(foreach c, $(COMPONENTS), $(eval $(call CONFIGURE_DOXYGEN_TEMPLATE,$c)))
$(foreach c, $(COMPONENTS), $(eval $(call CLEANUP_TEMPLATE,$c)))

# For each of the libs defined in the LIBRARIES variable of the Makefile, 
# generate the rules required to make the requested target:
$(foreach l, $(LIBRARIES), $(eval $(call SETUP_MAKE_VARIABLES,$l,lib)))
$(foreach l, $(LIBRARIES), $(eval $(call MKDIR_BUILD_DIRECTORIES_TEMPLATE,$l)))
$(foreach l, $(LIBRARIES), $(eval $(call GENERATE_BUILD_DEPENDS_TEMPLATE,$l,library)))
$(foreach l, $(LIBRARIES), $(eval $(call BUILD_OBJECTS_TEMPLATE,$l,src,library)))
$(foreach l, $(LIBRARIES), $(eval $(call MAKE_OBJECT_BUILD_DIRS_TEMPLATE,$l)))
$(foreach l, $(LIBRARIES), $(eval $(call BUILD_SHARED_OBJECT_TEMPLATE,$l)))
$(foreach l, $(LIBRARIES), $(eval $(call CLEANUP_TEMPLATE,$l)))

# For each of the tests defined in the TESTS variable of the Makefile, 
# generate the rules required to make the requested target:
$(foreach t, $(TESTS), $(eval $(call SETUP_MAKE_VARIABLES,$t,test)))
$(foreach t, $(TESTS), $(eval $(call MKDIR_BUILD_DIRECTORIES_TEMPLATE,$t)))
$(foreach t, $(TESTS), $(eval $(call GENERATE_BUILD_DEPENDS_TEMPLATE,$t,test)))
$(foreach t, $(TESTS), $(eval $(call GENERATE_TEST_RUNNER_TEMPLATE,$t)))
$(foreach t, $(TESTS), $(eval $(call GENERATE_CMOCK_TEMPLATE,$t)))
$(foreach t, $(TESTS), $(eval $(call BUILD_OBJECTS_TEMPLATE,$t,test)))
$(foreach t, $(TESTS), $(eval $(call BUILD_TESTING_OBJECTS_TEMPLATE,$t)))
$(foreach t, $(TESTS), $(eval $(call MAKE_OBJECT_BUILD_DIRS_TEMPLATE,$t)))
$(foreach t, $(TESTS), $(eval $(call BUILD_TEST_RUNNER_TEMPLATE,$t)))
$(foreach t, $(TESTS), $(eval $(call RUN_TEST_RUNNER_TEMPLATE,$t)))
$(foreach t, $(TESTS), $(eval $(call CLEANUP_TEMPLATE,$t)))
$(foreach t, $(TESTS), $(eval $(call RUN_COVERAGE_TEMPATE,$t)))

#
# Speficy the rule to ensure the ZSYS environment variables have been set. The
# zSys buildsystem is unable to make anything without these being set.
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
clean-doxy-conf: env-check
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
build-dirs: env-check $(MAKEDIRS) | $(ZSYS_SHARED_INCS_PATH) $(ZSYS_SHARED_BIN_PATH) $(ZSYS_SHARED_LIBS_PATH) $(ZSYS_DOXYGEN_PATH)

#
# A rule to gather (and build) the dependencies required to build a component
#
depends: env-check $(MAKE_COMPONENT_DEPENDS) $(MAKE_LIBRARY_DEPENDS)

#
# A rule to gather (and build) the dependencies required to build a test runner
#
test-depends: env-check $(MAKE_TEST_DEPENDS)

#
# A rule to build the defined list of COMPONENTS (includes code coverage)
#
build: env-check build-dirs depends $(COMPONENTS) $(LIBRARIES) 

#
# TODO: This is just a thought.....
# A rule to build the defined list of COMPONENTS (stripped for release)
#
release: env-check build-dirs depends $(COMPONENTS_REL) $(LIBRARIES_REL) 

#
# A rule to build and run the defined list of TESTS
#
test: env-check build-dirs test-depends $(TESTS) $(RUN_COVERAGE)
	@echo "==================================================================="
	@echo "TESTS COMPLETE!"
	@echo "==================================================================="

#
# A rule to run doxygen for the list of defined COMPONENTS
#
docs: env-check build-dirs clean-doxy-conf $(MAKE_DOCS)
	echo "OUTPUT_DIRECTORY = $(ZSYS_DOXYGEN_PATH)" >> $(ZSYS_DOXYGEN_CONFIG_FILE)
	echo "STRIP_FROM_PATH = ${ZSYS_ROOT}/components" >> $(ZSYS_DOXYGEN_CONFIG_FILE)
	$(DOXYGEN) $(ZSYS_DOXYGEN_CONFIG_FILE)
	@echo "==================================================================="
	@echo "GENERATED DOCS: $(strip $(ZSYS_DOXYGEN_PATH))/html/index.html"
	@echo "==================================================================="


#
# A rule to cleanup all the build artifacts
#
clean: env-check clean-doxy-conf $(CLEANUP)

#
# A rule to build everything, clean, build the test
#
.PHONY all:
all: env-check clean build-dirs depends test-depends build test 

