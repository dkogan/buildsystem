#include <stdio.h>
#include "libA/a.h"

int main(void)
{
  printf("utila 2\n");
#ifdef UTILA2
  printf("UTILA2 defined\n");
#endif

  funca();

  return 0;
}
