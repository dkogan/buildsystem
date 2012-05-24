#include <stdio.h>
#include "libC/c.generated.h"

void funcc(void)
{
#ifdef C
  printf("C defined\n");
#endif
  printf("GLOBAL_EXTRA: %d\n", GLOBAL_EXTRA);
  printf("GLOBAL_EXTRA_OTHER: %d\n", GLOBAL_EXTRA_OTHER);
  printf("c\n");
  printf("gen: %d\n", gen);
}
