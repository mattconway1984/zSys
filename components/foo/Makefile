
COMPONENTS = foo
foo_SOURCES = src/foo.c
foo_DEPENDS = bar

TESTS = test_foo
test_foo_TESTING = foo
test_foo_SOURCES = test/test_foo.c
test_foo_UNITY = test/test_foo.c
test_foo_DEPENDS = cmock unity foo
test_foo_CMOCK = bar

include ../../buildsys/common/rules.mk
