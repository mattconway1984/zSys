
#include "bar.h"
#include <stdio.h>

void bar_start(int zed)
{
    printf("bar started\n");
}

void bar_stop(void)
{
    printf("bar stopped\n");
}

/**
 * @brief some helper function
 */
void xyz(void)
{
    printf("XYZ");
}

void bar_not_used(void)
{
    xyz();
    printf("bar not used\n");
}

