# DESCRIPTION:
#  This file is used to set and configure tools used by the zSys buildsystem.
#  It should be ensured that no tool is *directly* invoked from any Makefile,
#  rather it should always use tools specified by this file, i.e. Do not do the
#  following inside a Makefile:
#    rm -rf <DIR>
#  Instead, use:
#    $(RMDIR) <DIR>
#  Where the tool to remove a directory *RMDIR* must be specified in this file.


# Set the C compiler tool and the options it should use
CC = gcc
CFLAGS = \
	-fPIC \
	--coverage
CFLAGS_STRICT = \
	-Wall \
	-Werror \
	-Wextra \
	-Wmissing-prototypes \
	-Wstrict-prototypes \
	-Wmissing-declarations \
	-Wold-style-definition \
	-Wunreachable-code \
	-Wnested-externs \
	-Wshadow \
	-Winline \
	-Wundef \
	-Wnested-externs \
	-Wbad-function-cast \
	-pedantic \
	-fstack-protector 
LFLAGS = 
LFLAGS_COV = \
	-fprofile-arcs
LFLAGS_SO = \
	-shared

# Set the CXX compiler tool and the options it should use
CCX = g++
CXXFLAGS = \
	-g \
	-fPIC \
	-fprofile-arcs \
	-ftest-coverage
CXXFLAGS_STRICT = \
	-Wall \
	-Werror \
	-Wextra \
	-Wmissing-declarations \
	-Wunreachable-code \
	-Wshadow \
	-Winline \
	-pedantic \
	-fstack-protector 
LXXFLAGS =
LXXFLAGS_COV = \
	-fprofile-arcs
LXXFLAGS_SO = \
	-shared

# Set the tools which are used to "do stuff"
MKDIR = mkdir -p
CPFILE = cp -r
RMDIR = rm -rf
RUBY = ruby
GCOV = gcov -r -d -n
DOXYGEN = doxygen

# Set the UNITY script that auto-generates test suite runners
UNITY_GENERATE_TEST_RUNNER = ${ZSYS_ROOT}/buildsys/tools/unity/generate_test_runner.rb

# Set the CMOCK script that auto-generates mocks
CMOCK_GENERATE_MOCK = ${ZSYS_ROOT}/buildsys/tools/cmock/create_mock.rb

