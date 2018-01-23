#include <stdlib.h>
#include <iostream>
#include <stdio.h>
#include <string.h>

#include <opencv2/opencv.hpp>

#include <lua5.2/lua.h>
#include <lua5.2/lauxlib.h>
#include <lua5.2/lualib.h>

/*
#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
*/

using namespace std;
using namespace cv;

extern int tags_n;
extern double tags_pos[50][10];

extern int boxes_n;
extern double boxes_pos[50][10];

///////////////////////////////////////////// init step and close //////////////
int testbench_init(int SystemWeight, int SystemHeight);
int testbench_step();
int testbench_close();
