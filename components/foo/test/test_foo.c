/**
 * An example source file containing unit tests that have been written to work
 * with the Unity unit test framework. Also using CMOCK to verify the external
 * API calls made by the eventbus component.
 */

/* Include the unity and cmock library headers */
#include "unity.h"
#include "cmock.h"

/* Include the code under test */
#include "foo.h"

/* The zSys buildsystem will invoke unity to generate the header for this file,
 * so it should be included here
 */
#include "test_foo.h"

/* The zSys buildsystem will invoke cmock to generate a mock implementation for
 * the zSys component "bar"
 */
#include "mock_bar.h"

void setUp(void)
{
    mock_bar_Init();
}

void tearDown(void)
{
    mock_bar_Verify();
}

void test_foo_start(void)
{
    /* foo_start will call bar_start(10). Setup mock bar to expect this call */
    bar_start_Expect(10);

    /* Call the code under test, cMock will verify that the code under test
     * called the mock with the correct value (10)
     */ 
    foo_start(1);
}

