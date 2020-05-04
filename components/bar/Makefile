# This Makefile explains how to build a ZSYS component.


# Specify at least one ZSYS component to be built:
COMPONENTS = bar

# Explicitly specify the list of source files that make up the component:
bar_SOURCES = src/bar.c

# Explicitly list all the (shared object) dependencies for the test runner:
bar_DEPENDS = 



# Specify at least one test runner
TESTS = test_bar

# Specify which source file is the UNITY test runner (used to auto generate 
# the test runner by calling unity/generate_test_runner.rb)
test_bar_UNITY = test/test_bar.c

# Explicitly list the source files required to build the test runner
test_bar_SOURCES = test/test_bar.c

# Explicitly list the shared library object being unit tested:
test_bar_TESTING = bar

# Explicitly list all the (shared object) dependencies for the test runner:
test_bar_DEPENDS = unity bar


include ../../buildsys/common/rules.mk
