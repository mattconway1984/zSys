# @Copyright 2018 Owlstone Medial Ltd, All Rights Reserved
#
# Description: Defines tools used by the zsys buildsystem.

include ${ZSYS_ROOT}/buildsys/common/globals.mk

MKDIR = mkdir -p
CPDIR = cp -r
RMDIR = rm -rf
RMFILE = rm
MV = mv

CC = gcc
CFLAGS = \
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
	-fstack-protector \
	-fPIC \
	-fprofile-arcs \
	-ftest-coverage
CFLAGS_INC = -I $(SHARED_INCS_ROOT)

CXX = g++
CXXFLAGS = \
	-Wall \
	-Werror \
	-Wextra \
	-Wmissing-declarations \
	-Wunreachable-code \
	-Wshadow \
	-Winline \
	-pedantic \
	-fstack-protector \
	-fPIC \
	-fprofile-arcs \
	-ftest-coverage
CXXFLAGS_INC = -I $(SHARED_INCS_ROOT)

# Linker options
LFLAGS = -shared 
LFLAGS_COVERAGE = -fprofile-arcs 

GCOV = gcov -r -d -n

include ${ZSYS_ROOT}/buildsys/common/globals.mk

# For UNITY and CMOCK set the paths for the ruby scripts:
RUBY = ruby
UNITY_GENERATE_TEST_RUNNER = ${ZSYS_ROOT}/buildsys/tools/unity/generate_test_runner.rb
CMOCK_GENERATE_MOCK = ${ZSYS_ROOT}/buildsys/tools/cmock/create_mock.rb

