
#include <stdio.h>

#include "unity.h"

#include "bar.h"

#include "test_bar.h"

void SetUp(void)
{
    printf("Stuff to run before each test\n");
}

void TearDown(void)
{
    printf("Stuff to run after each test\n");
}

void test_bar_start(void)
{
    bar_start(10);
}

void test_bar_stop(void)
{
    bar_stop();
}

