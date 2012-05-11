#include <stdio.h>
#include "libB/b.h"

void funca(void)
{
#ifdef A
  printf("A defined\n");
#endif
  printf("a\n");
  funcb();
}
