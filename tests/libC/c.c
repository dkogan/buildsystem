#include <stdio.h>
#include "libC/c.generated.h"

void funcc(void)
{
#ifdef C
  printf("C defined\n");
#endif
  printf("c\n");
  printf("gen: %d\n", gen);
}
