#include <stdio.h>
#include "libC/c.h"

void funcb(void)
{
  printf("b\n");
  funcc();
}
