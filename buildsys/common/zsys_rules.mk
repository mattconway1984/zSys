# @Copyright 2018 Owlstone Medial Ltd, All Rights Reserved
#
# Description: Global rules to define how the build system works

# TODO : Support different build targets:
# This could be set either:
#  1. By an external script setting environment variables (I like this method)
#  2. By a make rule, i.e. make test-linux, make dist-linux etc...
ENV_TARGET = 



include ${ZSYS_ROOT}/buildsys/common/globals.mk
include ${ZSYS_ROOT}/buildsys/common/tools.mk



#
# Make does not provide a recursive wildcard function, but we can write one:
#
rwildcard=$(wildcard $1$2) $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2))



#
# Function to define the key source directories required to build the
# component or library:
#   $1 is the name of the component/library
#   $2 should be set either: components or libraries, used to specify the path
define GENERATE_SOURCE_ROOT_TEMPLATE
# TODO : This is a little hacky so fix it up later
ifeq "$(2)" "tests"
$(1)_SOURCE_ROOT = $$(ZSYS_ROOT)/$$($(1)_ROOT)
$(1)_INC_DIR = $$($(1)_SOURCE_ROOT)
$(1)_SOURCE_DIR = $$($(1)_SOURCE_ROOT)
$(1)_TEST_DIR = $$($(1)_SOURCE_ROOT)/test
else
$(1)_SOURCE_ROOT = $$(ZSYS_ROOT)/$(2)/$(1)
$(1)_INC_DIR = $$($(1)_SOURCE_ROOT)/inc
$(1)_SOURCE_DIR = $$($(1)_SOURCE_ROOT)/src
endif
endef



#
# Function to retrieve the public include files defined for the component
#
define LIST_PUBLIC_INCLUDES_TEMPLATE
# Use the recursive wildcard function (defined above) to discover ALL the
# header files that reside in the COMPONENT/inc directory. Note: it's important
# to keep the sub-directory paths so they can be reconstructed
$(1)_INCS = $(call rwildcard,$($(1)_INC_DIR),*.h)
$(1)_INCS += $(call rwildcard,$($(1)_INC_DIR),*.hpp)
endef



# 
# Create rules to create the build directory for each target
#  $1 is the name of the target
#  $2 should be set to: components, libraries or applications (the path)
#
define MKDIR_BUILD_DIRECTORY_TEMPLATE
$(1)_BUILD_ROOT = $$(OBJECTS_ROOT)/$(2)/$(1)
$$($(1)_BUILD_ROOT): 
	$(MKDIR) $$@
endef



#
# Create rules to create the public includes for the component (copy them
# from source to build directory).
#
define GEN_PUBLIC_INCLUDES_TEMPLATE 
# The headers must be copied over to the build directory so they become 
# "public":
$(1)_INCLUDES = $(patsubst $($(1)_INC_DIR)/%,$(SHARED_INCS_ROOT)/%,$($(1)_INCS))
# The '%' in patsubst must be hidden otherwise it will be escaped:
PERCENT := %
# Making this a phony rule forces zSys buildsystem to copy over the public
# headers every time make is invoked; it's difficult to setup a watch on these
# files to copy them over only when they change and it's not a lot of build
# time to copy a file.
.PHONY: $$($(1)_INCLUDES)
$$($(1)_INCLUDES): $$(SHARED_INCS_ROOT) 
	$(MKDIR) $$(dir $$@)
	$(CPDIR) $$(patsubst $(SHARED_INCS_ROOT)/$$(PERCENT),$($(1)_INC_DIR)/$$(PERCENT),$$@) $$@
endef



#
# Create a rule that tells the buildsystem how to generate the unit test runner
# if it is required.
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
		$$($(1)_SOURCE_DIR)/$$($(1)_UNITY) \
		$$($(1)_SOURCE_DIR)/$$($(1)_UNITY_TEST_RUNNER_SOURCE) \
		--header_file="$$($(1)_SOURCE_DIR)/$$($(1)_UNITY_TEST_RUNNER_HEADER)"
endif
endef


define FOOBAR
	$(RUBY) \
		$(CMOCK_GENERATE_MOCK) \
		--input /home/mconway/dev/ninox/zsys/build/include/$$(2).h \
	    --output $$($(1)_TEST_DIR) \
		--prefix _mock
endef



define GENERATE_CMOCK_FILES_TEMPLATE
GEN_SOURCE = $$(patsubst %,test/$(CMOCK_PREFIX)%.c,$(2))
GEN_HEADER = $$(patsubst %,test/$(CMOCK_PREFIX)%.h,$(2)) 
$(1)_CMOCK_SOURCES := $$($(1)_CMOCK_SOURCES) $$(GEN_SOURCE) 
$(1)_CMOCK_HEADERS := $$($(1)_CMOCK_HEADERS) $$(GEN_HEADER)
$$(GEN_SOURCE):
	ruby \
		$(CMOCK_GENERATE_MOCK) \
		--input $(BUILD_ROOT)/include/$(2).h \
	    --output $$($(1)_TEST_DIR) \
		--prefix $(CMOCK_PREFIX) 
$$(GEN_HEADER):
	ruby \
		$(CMOCK_GENERATE_MOCK) \
		--input $(BUILD_ROOT)/include/$(2).h \
	    --output $$($(1)_TEST_DIR) \
		--prefix $(CMOCK_PREFIX) 
endef



#
# Create a rule for each mock specified in the _CMOCK list which tells the 
# buildsystem how to generate that mock file. 
#
# The headers that can be mocked live here:
#   <ZSYS>/build/include
#
# CMOCK will put the auto generated files here:
#   $(1)_TEST_DIR/generated[.h|.c]
#
#  $1 is the name of the target executable
#
define GENERATE_CMOCK_TEMPLATE
ifdef $(1)_CMOCK
$(foreach m, $$($(1)_CMOCK), $(eval $(call GENERATE_CMOCK_FILES_TEMPLATE,$(1),$(m))))
$(1)_SOURCES := $$($(1)_CMOCK_SOURCES) $$($(1)_SOURCES)
endif
endef



# 
# Create rules to build each object file required to build the target
#  $1 is the name of the target
#  $2 is the name of the source file directory (either src or test)
#  $3 should be set to: components, libraries, unittests or applications,
#     (used to specify the path where to put the built objects)
#  $4 flag set to:
#  		0 = Do not use CFLAGS when compiling
#  		1 = Use CFLAGS when compiling
#
define BUILD_OBJECTS_TEMPLATE
#   For example, if the component is "foo", and $(foo_SOURCES) was:
#     src/a.cpp
#     src/b.c
#   Then $(foo_OBJECTS) will be created to be:
#     build/a.cpp.o
#     build/b.c.o
$(1)_OUTPUTS = $(patsubst $(2)/%,$($(1)_BUILD_ROOT)/%,$($(1)_SOURCES))
$(1)_OBJECTS = $$($(1)_OUTPUTS:%=%.o)
ifeq "$(4)" "0"
#   Generate a "pattern rule" to build objects from CPP sources:
$$($(1)_BUILD_ROOT)/%.cpp.o: $(2)/%.cpp $$($(1)_INCLUDES) $$($(1)_BUILD_ROOT) 
	@echo "building: $$@ from $$<"
	$(CXX) -c $$< -o $$@ \
		-fPIC \
		$($(1)_SYMBOLS) \
		-I$($(1)_SOURCE_DIR) \
		-I$(SHARED_INCS_ROOT) \
		-L$(SHARED_LIBS_ROOT)
#   Generate a "pattern rule" to build objects from CC sources:
$$($(1)_BUILD_ROOT)/%.cc.o: $(2)/%.cc $$($(1)_INCLUDES) $$($(1)_BUILD_ROOT) 
	@echo "building: $$@ from $$<"
	$(CXX) -c $$< -o $$@ \
		-fPIC \
		$($(1)_SYMBOLS) \
		-I$($(1)_SOURCE_DIR) \
		-I$(SHARED_INCS_ROOT) \
		-L$(SHARED_LIBS_ROOT)
#   Generate a "pattern rule" to build objects from C sources:
$$($(1)_BUILD_ROOT)/%.c.o: $(2)/%.c $$($(1)_INCLUDES) $$($(1)_BUILD_ROOT)
	@echo "building: $$@ from $$<"
	$(CC) -c $$< -o $$@ \
		-fPIC \
		$($(1)_SYMBOLS) \
		-I$($(1)_SOURCE_DIR) \
		-I$(SHARED_INCS_ROOT) \
		-L$(SHARED_LIBS_ROOT)
else
#   Generate a "pattern rule" to build objects from CPP sources:
$$($(1)_BUILD_ROOT)/%.cpp.o: $(2)/%.cpp $$($(1)_INCLUDES) $$($(1)_BUILD_ROOT) 
	@echo "building: $$@ from $$<"
	$(CXX) -c $$< -o $$@ \
		$(CXXFLAGS) \
		$($(1)_SYMBOLS) \
		-I$($(1)_SOURCE_DIR) \
		-I$(SHARED_INCS_ROOT) \
		-L$(SHARED_LIBS_ROOT)
#   Generate a "pattern rule" to build objects from CC sources:
$$($(1)_BUILD_ROOT)/%.cc.o: $(2)/%.cc $$($(1)_INCLUDES) $$($(1)_BUILD_ROOT) 
	@echo "building: $$@ from $$<"
	$(CXX) -c $$< -o $$@ \
		$(CXXFLAGS) \
		$($(1)_SYMBOLS) \
		-I$($(1)_SOURCE_DIR) \
		-I$(SHARED_INCS_ROOT) \
		-L$(SHARED_LIBS_ROOT)
#   Generate a "pattern rule" to build objects from C sources:
$$($(1)_BUILD_ROOT)/%.c.o: $(2)/%.c $$($(1)_INCLUDES) $$($(1)_BUILD_ROOT)
	@echo "building: $$@ from $$<"
	$(CC) -c $$< -o $$@ \
		$(CFLAGS) \
		$($(1)_SYMBOLS) \
		-I$($(1)_INC_DIR) \
		-I$($(1)_SOURCE_DIR) \
		-I$(SHARED_INCS_ROOT) \
		-L$(SHARED_LIBS_ROOT)
endif
endef




# 
# Create rules to build each target
#  $1 is the name of the target
#  $2 should be set to: components, libraries or applications (the path)
#
define BUILD_TARGET_TEMPLATE
$(1): $$($(1)_OBJECTS) $$(SHARED_LIBS_ROOT) 
ifneq "$$$$(wildcard $$($(1)_OBJECTS).c.o)" ""
	$(CC) -o $$(SHARED_LIBS_ROOT)/lib$(1).so \
		$$($(1)_OBJECTS) \
		$(LFLAGS) \
		$(LFLAGS_COVERAGE) 
else ifeq "$$$$(wildcard $$($(1)_OBJECTS).cpp.o)" ""
	$(CXX) -o $$(SHARED_LIBS_ROOT)/lib$(1).so \
		$$($(1)_OBJECTS) \
		$(LFLAGS) \
		$(LFLAGS_COVERAGE) 
endif
	@echo "Successfuly built $$@"
endef



define REMOVE_TEMPORARY_FILE_TEMPLATE
endef

#
# Create rules to build an executable template
#  $1 is the name of the target executable
#  $2 should be set to app OR tests (the type of executable)
#
define BUILD_EXECUTABLE_TEMPLATE
ifneq "$$(wildcard $($(1)_OBJECTS).c.o)" ""
LDD = $$(CC)
UNITY = "TRUE"
CMOCK = "TRUE"
else 
LDD = $$(CXX)
UNITY = "FALSE"
CMOCK = "FALSE"
endif
$(1): $$($(1)_OBJECTS) $(EXECUTABLES_ROOT) 
	$(MKDIR) $(EXECUTABLES_ROOT)/$(2)
	$$(LDD) \
		$$($(1)_OBJECTS) \
		$(LFLAGS_COVERAGE) \
		$($(1)_SYMBOLS) \
		-I $(SHARED_INCS_ROOT) \
		-L $(SHARED_LIBS_ROOT) \
		$$(patsubst %,-l%,$$($(1)_DEPENDS)) \
		-o $$(EXECUTABLES_ROOT)/$(2)/$(1) 
ifeq "$$(UNITY)" "TRUE"
	@echo "==================================================================="
	@echo "Removing *temporary* auto generated sources"
	$(RMFILE) $($(1)_SOURCE_DIR)/$($(1)_UNITY_TEST_RUNNER_SOURCE)
	$(RMFILE) $($(1)_SOURCE_DIR)/$($(1)_UNITY_TEST_RUNNER_HEADER)
endif
ifeq "$$(CMOCK)" "TRUE"
	$(RMFILE) $($(1)_CMOCK_SOURCES)
	$(RMFILE) $($(1)_CMOCK_HEADERS)
endif
	@echo "==================================================================="
	@echo "RUNNING TESTS [$$@]"
	$$(EXECUTABLES_ROOT)/$(2)/$(1)
	@echo "==================================================================="
	@echo "RUNNING COVERAGE [$$@]"
	$$(GCOV) $$(OBJECTS_ROOT)/components/$$($(1)_COVERAGE)/*.*.gcno
endef



# 
# Default rule is "make all", which for now will build the $(COMPONENT):
#
all: $(COMPONENT) $(LIBRARY)
	@echo "Build Complete"


#
# Rule to run unit tests
#
test: $(TESTS)
	@echo "Test Complete"



# 
# Create the dynamic rules required to build each component, for now, there is
# only one COMPONENT....
#
$(foreach c, $(COMPONENT), $(eval $(call GENERATE_SOURCE_ROOT_TEMPLATE,$c,components)))
$(foreach c, $(COMPONENT), $(eval $(call LIST_PUBLIC_INCLUDES_TEMPLATE,$c)))
$(foreach c, $(COMPONENT), $(eval $(call GEN_PUBLIC_INCLUDES_TEMPLATE,$c)))
$(foreach c, $(COMPONENT), $(eval $(call MKDIR_BUILD_DIRECTORY_TEMPLATE,$c,components)))
$(foreach c, $(COMPONENT), $(eval $(call BUILD_OBJECTS_TEMPLATE,$c,src,components,1))) 
$(foreach c, $(COMPONENT), $(eval $(call BUILD_TARGET_TEMPLATE,$c,components)))



#
# Create the dynamic rules required to build each library, for now, there is 
# only one LIBRARY....
#
$(foreach l, $(LIBRARY), $(eval $(call GENERATE_SOURCE_ROOT_TEMPLATE,$l,libraries)))
$(foreach l, $(LIBRARY), $(eval $(call LIST_PUBLIC_INCLUDES_TEMPLATE,$l)))
$(foreach l, $(LIBRARY), $(eval $(call GEN_PUBLIC_INCLUDES_TEMPLATE,$l)))
$(foreach l, $(LIBRARY), $(eval $(call MKDIR_BUILD_DIRECTORY_TEMPLATE,$l,libraries)))
$(foreach l, $(LIBRARY), $(eval $(call BUILD_OBJECTS_TEMPLATE,$l,src,libraries,0)))
$(foreach l, $(LIBRARY), $(eval $(call BUILD_TARGET_TEMPLATE,$l,libraries)))



#
# Create the dynamic rules required to build the unit tests
#
$(foreach t, $(TESTS), $(eval $(call GENERATE_SOURCE_ROOT_TEMPLATE,$t,tests)))
$(foreach t, $(TESTS), $(eval $(call MKDIR_BUILD_DIRECTORY_TEMPLATE,$t,tests)))
$(foreach t, $(TESTS), $(eval $(call GENERATE_TEST_RUNNER_TEMPLATE,$t,tests)))
$(foreach t, $(TESTS), $(eval $(call GENERATE_CMOCK_TEMPLATE,$t,tests)))
$(foreach t, $(TESTS), $(eval $(call BUILD_OBJECTS_TEMPLATE,$t,test,tests,1)))
$(foreach t, $(TESTS), $(eval $(call BUILD_EXECUTABLE_TEMPLATE,$t,tests)))



# 
# Rules to create build directories:
#
$(BUILD_ROOT):
	$(MKDIR) $@
$(SHARED_LIBS_ROOT): $(BUILD_ROOT)
	$(MKDIR) $@
$(SHARED_INCS_ROOT): $(BUILD_ROOT)
	$(MKDIR) $@
$(EXECUTABLES_ROOT): $(BUILD_ROOT)
	$(MKDIR) $@
$(COVERAGE_ROOT): $(BUILD_ROOT)
	$(MKDIR) $@
