#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "mpi.h"

int isprime(int n){
	long long int i, squareroot;
	if(n>10){
		squareroot = (long long int) sqrt(n);
		for(i=3; i<=squareroot; i=i+2)
			if((n%i)==0)	return 0;
		return 1;
	}
	else
		return 0;
}

int main(int argc, char **argv){
	int rank, tasks;
	long long int pc_local, pc_global, step;
	long long int n, limit, foundone, max_prime;

	sscanf(argv[1], "%llu", &limit);

	MPI_Init(&argc, &argv);
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &tasks);

	step = tasks*2;
	pc_local = 0;	pc_global = 0;
	foundone = 0;	max_prime = -1;
//	printf("%d / %d\n", rank, tasks);
	if(rank == 0){
		printf("Starting. Numbers to be scanned= %lld\n", limit);
		pc_local = 4;	/* Assume (2,3,5,7) are counted here */
	}

	for(n=11+rank*2; n<=limit; n=n+step){
		if(isprime(n)){
			pc_local++;
			foundone = n;
		}
	}

	MPI_Reduce(&pc_local, &pc_global, 1, MPI_LONG_LONG_INT, MPI_SUM, 0, MPI_COMM_WORLD);
	MPI_Reduce(&foundone, &max_prime, 1, MPI_LONG_LONG_INT, MPI_MAX, 0, MPI_COMM_WORLD);

	if(rank == 0)
		printf("Done. Largest prime is %d Total primes %d\n", max_prime, pc_global);
	MPI_Finalize();
	return 0;

}
