#include <stdio.h>

void funcb2(void)
{
#ifdef B2
  printf("B2 defined\n");
#else
  printf("B2 not defined\n");
#endif
}
