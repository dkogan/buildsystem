#include <stdio.h>
#include "libC/c.h"

void funcb(void)
{
#ifdef B
  printf("B defined\n");
#endif
  printf("b\n");
  funcc();
}
