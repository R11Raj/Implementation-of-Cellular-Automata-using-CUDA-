#include <cuda.h>
#include <iostream>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
#include <stdio.h>
// defining minimum and maximum sizes 
#define minSize 1024
#define maxSize 8192

using namespace std;

// function to print the current state
void StatePrint(int *a,long SIZE)
{
  for (unsigned y = 1; y < SIZE - 1; y++)
  {
    for (unsigned x = 1; x < SIZE - 1; x++)
    {
        a[y*SIZE+x] == 1 ? cout << char(219) << char(219) : cout << ' ' << ' ';
    }
    cout << endl;
  }
}

// function to build a random state in the grid
void randomGrid(int *a,long SIZE)
{
  srand(time(NULL));
  for (int y = 1; y < SIZE - 1; y++)
  {
    for (int x = 1; x < SIZE - 1; x++)
    {
      a[y*SIZE+x] = rand() % 2;
    }
  }
}

// function to add a blinker to the grid
void addBlinker(int *a, int i, int j,long SIZE)
{
  int b[][3] = {{0, 1, 0}, {0, 1, 0}, {0, 1, 0}};
  for (int p = 0; p < 3; p++)
  {
    for (int q = 0; q < 3; q++)
    {
 a[(i + p)*SIZE+j + q] = b[p][q];
    }
  }
}

// function to add a Glider to the grid at some coordinates
void addGlider(int *a, int i, int j,long SIZE)
{
  int b[][3] = {{0, 0, 1},
                {1, 0, 1},
                {0, 1, 1}};
  for (int p = 0; p < 3; p++)
  {
    for (int q = 0; q < 3; q++)
    {
      a[(i + p)*SIZE+j + q] = b[p][q];
    }
  }
}

// function to add a Glider gun to the grid at some coordinates
void addGliderGun(int *a, int i, int j,long SIZE)
{
  int b[11][38] = {0};
  b[5][1] = b[5][2] = 1;
  b[6][1] = b[6][2] = 1;

  b[3][13] = b[3][14] = 1;
  b[4][12] = b[4][16] = 1;
  b[5][11] = b[5][17] = 1;
  b[6][11] = b[6][15] = b[6][17] = b[6][18] = 1;
  b[7][11] = b[7][17] = 1;
  b[8][12] = b[8][16] = 1;
  b[9][13] = b[9][14] = 1;

  b[1][25] = 1;
  b[2][23] = b[2][25] = 1;
  b[3][21] = b[3][22] = 1;
  b[4][21] = b[4][22] = 1;
  b[5][21] = b[5][22] = 1;
  b[6][23] = b[6][25] = 1;
  b[7][25] = 1;
b[3][35] = b[3][36] = 1;
  b[4][35] = b[4][36] = 1;

  for (int p = 0; p < 11; p++)
  {
    for (int q = 0; q < 38; q++)
    {
      a[(i + p)*SIZE+j + q] = b[p][q];
    }
  }
}

// Defining kernel function to simulate cellular automata 
__global__ void cellular_automata(int *a,int *b,long SIZE)
{
  int count = 0;
  // number of new states to be generated
  int loop=100;
  // getting thread id
  long int tid=blockIdx.x*blockDim.x+threadIdx.x;
  long int row,col;
  //figuring out row id and column id 
  row=int(tid/SIZE);
  col=tid%SIZE;
  
  // evaluating a cell 
  while(loop){
    for (int i = -1; i < 2; i++)
    {
      for (int j = -1; j < 2; j++)
      {
        if (i != 0 || j != 0)
          count += (a[(row + i)*SIZE +col + j] ? 1 : 0);
      }
    }
    b[row*SIZE+col] = a[row*SIZE+col] == 1 ? count == 3 || count == 2 ? 1 : 0 : count == 3 ? 1 : 0;

    loop--;
    
    a[row*SIZE+col] = b[row*SIZE+col];
  }
}

int main()
{
  int *a;
  
  int *d_a, *d_b;

  float e_time1,e_time2,e_time3,milliseconds,throughput;

  FILE *data=fopen("parallel_data.txt","w");

  for(long SIZE=minSize;SIZE<=maxSize;SIZE*=2)
  {
    // allocating space for grid 
    a=(int*)malloc(SIZE*SIZE*sizeof(int));

    // initialising grid with a random state
    randomGrid(a,SIZE);
    //addGlider(a, 100, 100);
    //addGliderGun(a, 225, 100);
    //addBlinker(a, 125, 130);
    //StatePrint(a);

    // allocating memory in cuda device
    cudaMalloc((void**)&d_a,SIZE*SIZE*sizeof(int));
    cudaMalloc((void**)&d_b,SIZE*SIZE*sizeof(int));

    // creating events to record different timings
    cudaEvent_t start1,stop1,start2,stop2,start3,stop3;
    cudaEventCreate(&start1);
    cudaEventCreate(&stop1);

    // copying memory from host to device
    cudaEventRecord(start1);
    cudaMemcpy(d_a,a,SIZE*SIZE*sizeof(int),cudaMemcpyHostToDevice);
    cudaEventRecord(stop1);

    // calculating memory copy time
    cudaEventSynchronize(stop1);
    milliseconds=0;
    cudaEventElapsedTime(&milliseconds, start1, stop1);
    e_time1=(double)milliseconds/1000;
    cout<<"HTOD:"<<e_time1<<endl;

    cudaEventCreate(&start2);
    cudaEventCreate(&stop2);

    // running the simulation
    cudaEventRecord(start2);
    for(int j=0;j<(maxSize/SIZE);j++)
    {
      cellular_automata<<<SIZE*SIZE/1024,1024>>>(d_a,d_b,SIZE);
    }
    cudaEventRecord(stop2);

    //calculating the compute time
    cudaEventSynchronize(stop2);
    milliseconds=0;
    cudaEventElapsedTime(&milliseconds, start2, stop2);
    e_time2=(double)milliseconds/1000;
    cout<<"Kernel:"<<e_time2<<endl;

    cudaEventCreate(&start3);
    cudaEventCreate(&stop3);

    // copying back the results of the simulation from device to host
    cudaEventRecord(start3);
    cudaMemcpy(a,d_a,SIZE*SIZE*sizeof(int),cudaMemcpyDeviceToHost);
    cudaEventRecord(stop3);

    // calculating memory copy time
    cudaEventSynchronize(stop3);
    milliseconds=0;
    cudaEventElapsedTime(&milliseconds, start3, stop3);
    e_time3=(double)milliseconds/1000;
    cout<<"DTOH:"<<e_time3<<endl;

    // calculating throughput
    throughput=(sizeof(float)*maxSize*maxSize)/e_time2;

    fprintf(data,"%lf,%lf,%lf,%lf\n",e_time1,e_time2*SIZE/maxSize,e_time3,throughput/1000000);
    
    // deallocating cuda device memory
    cudaFree(d_a);
    cudaFree(d_b);

    // deallocating grid space
    free(a);
  }

  cout<<"ENDED";
  return 0;
  // End of the Program
}
              