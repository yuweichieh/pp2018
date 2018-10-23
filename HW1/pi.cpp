#include <iostream>
#include <cstdlib>
#include <pthread.h>
using namespace std;

long long int ttl_success = 0;
pthread_mutex_t mutex;

void* rand_toss(void* count){
	unsigned int seed;
	seed = rand();
    long long int jobs_count = *(long long*)count;
    //	cout<< "Count: "<< jobs_count<< endl;
    long long int local_sum = 0;
    for(int i=0; i<jobs_count; i++){
        double x = (double)rand_r(&seed)/RAND_MAX;
        double y = (double)rand_r(&seed)/RAND_MAX;
        if(x*x + y*y <= 1.0)    local_sum++;
    }
    pthread_mutex_lock(&mutex);
    ttl_success += local_sum;
    pthread_mutex_unlock(&mutex);
    pthread_exit(NULL);
}

int main(int argc, char* argv[]){
    srand(time(NULL));
    int cpu_num = atoi(argv[1]);
    long long int toss_need = atoll(argv[2]);
    
    long long int* jobs_per_thread = (long long *)malloc(sizeof(long long));
    *jobs_per_thread = toss_need/cpu_num;
    long long int* jobs_w_remain = (long long *)malloc(sizeof(long long));
    *jobs_w_remain = *jobs_per_thread + toss_need - *jobs_per_thread * cpu_num;
    pthread_t thread_handles[cpu_num];
    pthread_mutex_init(&mutex, NULL);
    
    for(int i=0; i<cpu_num; i++){
        if(!i)
            pthread_create(&thread_handles[i], NULL, rand_toss, jobs_w_remain);
        else
            pthread_create(&thread_handles[i], NULL, rand_toss, jobs_per_thread);
    }
    
    for(int i=0; i<cpu_num; i++)
    	pthread_join(thread_handles[i], NULL);
    pthread_mutex_destroy(&mutex);
    double pi = 4.0 * ttl_success / toss_need;
    printf("%9.7f\n", pi);
    return 0;
}
