CC = gcc
CFLAGS = \
	-fPIC \
	-fprofile-arcs \
	-ftest-coverage
LFLAGS = 
LFLAGS_COV = \
	-fprofile-arcs
LFLAGS_SO = \
	-shared


MKDIR = mkdir -p
GCOV = gcov -n
CPFILE = cp -r
RMDIR = rm -rf

RUBY = ruby
UNITY_GENERATE_TEST_RUNNER = ${ZSYS_ROOT}/buildsys/tools/unity/generate_test_runner.rb
CMOCK_GENERATE_MOCK = ${ZSYS_ROOT}/buildsys/tools/cmock/create_mock.rb

DOXYGEN = doxygen

