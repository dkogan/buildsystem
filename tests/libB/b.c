#include <stdio.h>
#include "libC/c.h"
#include "libB/b2.h"

void funcb(void)
{
#ifdef B
  printf("B defined\n");
#endif
  printf("b\n");

  funcb2();

  funcc();
}
