/*********************************************************************
 * DESCRIPTION:
 *   Serial Concurrent Wave Equation - C Version
 *   This program implements the concurrent wave equation
 *********************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <cuda.h>

#define MAXPOINTS 1000000
#define MAXSTEPS 1000000
#define MINPOINTS 20
#define PI 3.14159265

void check_param(void);
void init_line(void);
void update (void);
void printfinal (void);

int nsteps,                 	/* number of time steps */
    tpoints, 	     		/* total points along string */
    rcode;                  	/* generic return code */
float  values[MAXPOINTS+2], 	/* values at time t */
       oldval[MAXPOINTS+2], 	/* values at time (t-dt) */
       newval[MAXPOINTS+2]; 	/* values at time (t+dt) */
float *d_values;	/* pointer to device memory */

/**********************************************************************
 *	Checks input values from parameters
 *********************************************************************/
void check_param(void)
{
   char tchar[20];

   /* check number of points, number of iterations */
   while ((tpoints < MINPOINTS) || (tpoints > MAXPOINTS)) {
      printf("Enter number of points along vibrating string [%d-%d]: "
           ,MINPOINTS, MAXPOINTS);
      scanf("%s", tchar);
      tpoints = atoi(tchar);
      if ((tpoints < MINPOINTS) || (tpoints > MAXPOINTS))
         printf("Invalid. Please enter value between %d and %d\n", 
                 MINPOINTS, MAXPOINTS);
   }
   while ((nsteps < 1) || (nsteps > MAXSTEPS)) {
      printf("Enter number of time steps [1-%d]: ", MAXSTEPS);
      scanf("%s", tchar);
      nsteps = atoi(tchar);
      if ((nsteps < 1) || (nsteps > MAXSTEPS))
         printf("Invalid. Please enter value between 1 and %d\n", MAXSTEPS);
   }

   printf("Using points = %d, steps = %d\n", tpoints, nsteps);

}

/**********************************************************************
 *     Initialize points on line
 *********************************************************************/
void init_line(void)
{
   int i, j;
   float x, fac, k, tmp;

   /* Calculate initial values based on sine curve */
   fac = 2.0 * PI;
   k = 0.0; 
   tmp = tpoints - 1;
   for (j = 1; j <= tpoints; j++) {
      x = k/tmp;
      values[j] = sin (fac * x);
      k = k + 1.0;
   } 

   /* Initialize old values array */
   for (i = 1; i <= tpoints; i++) 
      oldval[i] = values[i];
}

/**********************************************************************
 *      Calculate new values using wave equation
 *********************************************************************/
__device__ float do_math(float toldval, float tvalues)
{
   float dtime, c, dx, tau, sqtau;

   dtime = 0.3;
   c = 1.0;
   dx = 1.0;
   tau = (c * dtime / dx);
   sqtau = tau * tau;
	float tnewval;
	tnewval = (2.0 * tvalues) - toldval + (sqtau *  (-2.0)*tvalues);
	return tnewval;
}

/**********************************************************************
 *     Update all values along line a specified number of times
 *********************************************************************/
__global__ void update(float *d_values, int tpoints, int nsteps)
{
   int i, j;
	j = (1+threadIdx.x) + blockIdx.x*32;
	if( j <= tpoints ){
		float tvalues = d_values[j];
		float toldval = tvalues;
		float tnewval;
		for(i=1; i<=nsteps; i++){
			if((j==1) || (j==tpoints))
				tnewval = 0.0;
			else
				tnewval = do_math(toldval, tvalues);
			toldval = tvalues;
			tvalues = tnewval;
		}
		d_values[j] = tvalues;
	}
}

/**********************************************************************
 *     Print final results
 *********************************************************************/
void printfinal()
{
   int i;

   for (i = 1; i <= tpoints; i++) {
      printf("%6.4f ", values[i]);
      if (i%10 == 0)
         printf("\n");
   }
}

/**********************************************************************
 *	Main program
 *********************************************************************/
int main(int argc, char *argv[])
{
	sscanf(argv[1],"%d",&tpoints);
	sscanf(argv[2],"%d",&nsteps);
	cudaMalloc(&d_values, sizeof(float)*(1+tpoints));

	check_param();
	printf("Initializing points on the line...\n");
	init_line();
	cudaMemcpy(d_values, values, sizeof(float)*(1+tpoints), cudaMemcpyHostToDevice);

	printf("Updating all points for all time steps...\n");
	int block;
	if(tpoints%32){
		block = 1 + tpoints/32;
		update<<<block, 32>>>(d_values, tpoints, nsteps);
	}
	else{
		block = tpoints/32;
		update<<<block, 32>>>(d_values, tpoints, nsteps);
	}
	cudaMemcpy(values, d_values, sizeof(float)*(1+tpoints), cudaMemcpyDeviceToHost);

	printf("Printing final results...\n");
	printfinal();
	printf("\nDone.\n\n");
	cudaFree(d_values);
	return 0;
}
