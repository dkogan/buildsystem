#include <stdio.h>

void funcc(void)
{
#ifdef C
  printf("C defined\n");
#endif
  printf("c\n");
}
