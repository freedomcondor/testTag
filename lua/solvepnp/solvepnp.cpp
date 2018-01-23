extern "C"{
#include <stdio.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
}

#include <opencv2/opencv.hpp>

//g++ solvepnp.cpp -I/usr/include/lua5.2 -llua5.2 -fPIC -shared -o solvepnp.so
using namespace cv;
using namespace std;

/*		robot
const double m_fFx = 8.8396142504070610e+02;
const double m_fFy = 8.8396142504070610e+02;
// camera principal point
const double m_fPx = 3.1950000000000000e+02;
const double m_fPy = 1.7950000000000000e+02;
// camera distortion coefficients
const double m_fK1 = 1.8433447851104852e-02;
const double m_fK2 = 1.6727474183089033e-01;
const double m_fK3 = -1.5480889084966631e+00;
*/

//*		camera
const double m_fFx = 939.001439;
const double m_fFy = 939.001439;
// camera principal point
const double m_fPx = 320;
const double m_fPy = 240;
// camera distortion coefficients
const double m_fK1 = -0.4117914;
const double m_fK2 = 5.17498964;
const double m_fK3 = -17.7026842;
//*/

/* camera matrix */
const cv::Matx<double, 3, 3> cCameraMatrix =
      cv::Matx<double, 3, 3>(m_fFx, 0.0f, m_fPx,
	                        0.0f, m_fFy, m_fPy,
                            0.0f,  0.0f,  1.0f);
/* camera distortion parameters */
const cv::Matx<double, 5, 1> cDistortionParameters =
      cv::Matx<double, 5, 1>(m_fK1, m_fK2, 0.0f, 0.0f, m_fK3);

static int solvepnp(lua_State *L)
{
    double R;

	lua_pushstring(L,"halfL");		//stack 2
	lua_gettable(L,1);			//stack 2 is the corner {x = , y = }
	R = lua_tonumber(L,2);		// stack 2
	lua_pop(L,1);				// stack 2 gone (the corner)

    vector<cv::Point3d> ob;
    ob.push_back( Point3d(-R, -R, 0));
    ob.push_back( Point3d( R, -R, 0));
    ob.push_back( Point3d( R,  R, 0));
    ob.push_back( Point3d(-R,  R, 0));

	vector<cv::Point2d> im;

	//printf("\t\t\tI am solvepnp\n");
	double x,y;
	//lua_gettable(L,1);
	// stack 1 is the corners table
	for (int i = 1; i <= 4; i++)
	{
		lua_pushnumber(L,i);		//stack 2
		lua_gettable(L,1);			//stack 2 is the corner {x = , y = }
			lua_pushstring(L,"x");		// stack 3
			lua_gettable(L,2);			// stack 3 is the x
			x = lua_tonumber(L,3);		// stack 3 
			lua_pop(L,1);				// stack 3 gone

			lua_pushstring(L,"y");		// stack 3
			lua_gettable(L,2);			// stack 3 is the x
			y = lua_tonumber(L,3);		// stack 3 
			lua_pop(L,1);				// stack 3 gone

		lua_pop(L,1);					// stack 2 gone (the corner)
		//printf("i = %d, x = %lf, y = %lf\n",i,x,y);
		im.push_back( Point2d(x, y));
	}
	lua_pop(L,1);					// stack 1 gone (the corners)
	////////////////////////////

	Mat rotation_vector; // Rotation in axis-angle form
	Mat translation_vector;

	solvePnP(ob,im,cCameraMatrix,cDistortionParameters,rotation_vector, translation_vector,false,CV_P3P);
	//solvePnP(ob,im,cCameraMatrix,cDistortionParameters,rotation_vector, translation_vector,false);

	//cout << "rotation" << rotation_vector << endl;
	//cout << "translation" << translation_vector << endl;

	// convert from left handed to right handed
	lua_settop(L,0);					// stack 1 gone (the corners)
	lua_newtable(L);					// stack 1
		lua_pushstring(L,"rotation");		// stack 2
		lua_newtable(L);					// stack 3
			lua_pushstring(L,"x");		// stack 4
			lua_pushnumber(L,rotation_vector.at<Vec3d>(0,0)[0]);		// stack 5
		  lua_settable(L,3);
			lua_pushstring(L,"y");		// stack 4
			lua_pushnumber(L,-rotation_vector.at<Vec3d>(0,0)[1]);		// stack 5
		  lua_settable(L,3);
			lua_pushstring(L,"z");		// stack 4
			lua_pushnumber(L,-rotation_vector.at<Vec3d>(0,0)[2]);		// stack 5
		  lua_settable(L,3);
	  lua_settable(L,1);
		lua_pushstring(L,"translation");		// stack 2
		lua_newtable(L);					// stack 3
			lua_pushstring(L,"x");		// stack 4
			lua_pushnumber(L,-translation_vector.at<Vec3d>(0,0)[0]);		// stack 5
		  lua_settable(L,3);
			lua_pushstring(L,"y");		// stack 4
			lua_pushnumber(L,translation_vector.at<Vec3d>(0,0)[1]);		// stack 5
		  lua_settable(L,3);
			lua_pushstring(L,"z");		// stack 4
			lua_pushnumber(L,translation_vector.at<Vec3d>(0,0)[2]);		// stack 5
		  lua_settable(L,3);
	  lua_settable(L,1);

	return 1;
}

extern "C"{
//static const struct luaL_reg clib[] =
static const luaL_Reg clib[] =
{
	{"solvepnp",solvepnp},
	{NULL,NULL}
};

int luaopen_libsolvepnp(lua_State *L)
{
	lua_newtable(L);
	luaL_setfuncs(L,clib,0);
	lua_setglobal(L,"libsolvepnp");
	//luaL_openlib(L,"mylib",clib,0);
	return 1;
}

}// end extern c
