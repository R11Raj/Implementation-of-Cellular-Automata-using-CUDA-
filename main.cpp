#include <iostream>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>
// defining minimum and maximum sizes of the grid
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

// Defining function to simulate cellular automata 
void cellular_automata(int *a,int *b,long SIZE)
{
  int i, j,loop,count = 0;
  clock_t start_time,end_time;
  start_time = clock();
  for(int RUNS=0;RUNS<(maxSize/SIZE);RUNS++)
  {
  	// number of new states that is to be generated
    loop=50;
    while (loop > 0)
    {
    	// evaluating a cell
      for (long y = 1; y < SIZE - 1; y++)
      {
        for (long x = 1; x < SIZE - 1; x++)
        {
          count = 0;
          for (i = -1; i < 2; i++)
          {
            for (j = -1; j < 2; j++)
            {
              if (i != 0 || j != 0)
                count += (a[(y + i)*SIZE+x + j] ? 1 : 0);
            }
          }
          b[y*SIZE+x] = a[y*SIZE+x] == 1 ? count == 3 || count == 2 ? 1 : 0 : count == 3 ? 1 : 0;
          a[y*SIZE+x] = b[y*SIZE+x];
        }
      }
      loop--;
    }
  }  
  // execution time calculation
  end_time = clock()-start_time;
  double e_time=(double)end_time/CLOCKS_PER_SEC;
  cout<<start_time<<' '<<end_time<<endl;
  cout<<"E-time:"<<e_time*SIZE/maxSize<<endl;
  
  // throughput calculation
  float throughput=maxSize*SIZE*sizeof(float)/e_time;
  cout<<throughput<<endl;
}

// main function 
int main()
{
    
  for(long SIZE=minSize;SIZE<=minSize;SIZE=SIZE*2)
  {
    cout<<SIZE<<endl;
    int *a,*b;
    // allocating space for grid
    a=(int*)malloc(SIZE*SIZE*sizeof(int));
    b=(int*)malloc(SIZE*SIZE*sizeof(int));

	// initialising grid with a random state
    randomGrid(a,SIZE);
    
    // running the simulation
    cellular_automata(a,b,SIZE);

	//deallocating the space
    free(a);
    free(b);
  }
  return 0;
  // End of the Program
}
