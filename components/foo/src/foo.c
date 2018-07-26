
#include "foo.h"
#include "bar.h"
#include <stdio.h>

void foo_start(int zed)
{
    bar_start(10);
    printf("foo started\n");
}

void foo_stop(void)
{
    printf("foo stopped\n");
}

void xyz(void)
{
    printf("XYZ");
}

void foo_not_used(void)
{
    xyz();
    printf("foo not used\n");
}

