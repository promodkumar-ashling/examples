/*
 ============================================================================
 Name        : main.c
 Author      : Ashling
 Description : Hello World in C, Ansi-style
 ============================================================================
 */

#include <stdio.h>
#include <stdlib.h>

#define MAX_VALUE 10000
#define MIN_VALUE 0

/*--------------------------------------------------------------*/
/* Simple sum function that takes two arguments start number  	*/
/*(start) and end number(end) and compute the sum of the numbers*/
/* from start to end.  											*/
/*--------------------------------------------------------------*/
int sum(int start, int end)
{
	int sum = 0;
	for (int i = start; i <= end; i++)
	{
		sum += i;
	}
	return sum;
}

/*--------------------------------------------------------------*/
/* main function: call sum                                      */
/*--------------------------------------------------------------*/
int main()
{
	int x = 2, y = 8;
	while (1)
	{
		if (x > MAX_VALUE && y > MAX_VALUE)
		{
			x = 3;
			y = 9;
		}

		if (x < MIN_VALUE || y < MIN_VALUE)
		{
			x = 3;
			y = 9;
		}

		sum(x, y);
		x++;
		y++;
	}
	return 0;
}
