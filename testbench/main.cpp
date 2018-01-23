#include "testbench.h"

int main()
{
	int flag;
	printf("testbench,press p to pause, ESC to exit\n");

	flag = testbench_init(2048,1536);
	if (flag != 0)
		{printf("init wrong \n"); return -1;}

	while (testbench_step() == 0);

	testbench_close();

	return 0;
}
