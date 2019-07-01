LIBRARIES = cmock 
cmock_SOURCES = src/cmock.c
cmock_DEPENDS = unity

TESTS = test_cmock_c test_cmock_c_dynamic

test_cmock_c_TESTING = cmock
test_cmock_c_UNITY = test/TestCMockC.c
test_cmock_c_SOURCES = test/TestCMockC.c
test_cmock_c_DEPENDS = unity cmock

test_cmock_c_dynamic_TESTING = cmock
test_cmock_c_dynamic_UNITY = test/TestCMockCDynamic.c
test_cmock_c_dynamic_SOURCES = test/TestCMockCDynamic.c
test_cmock_c_dynamic_DEPENDS = unity cmock

include ../../buildsys/common/rules.mk
