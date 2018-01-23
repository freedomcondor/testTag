#include "testbench.h"

int drawLine(Mat img, int x1, int y1, int x2, int y2, const char colour[]);
int drawString(Mat img, int x1, int y1, char str[], const char colour[]);
int Num2Str(int x, char str[], int length);

///////////////////////// vars ////////////////////////////////////////
lua_State *L;
apriltag_detector* m_psTagDetector;
apriltag_family* m_psTagFamily;

////////// loop filename initail //////////////
char fileName[30];
char fileNameBase[20] = "../data/output_";
//char fileNameBase[20] = "data/output_";
char fileExt[10] = ".png";
char fileNumber[10];
string strFileName;
string strFileSuffix("output_");
std::string strFileExtension(".png");
int nTimestamp;

Mat imageRGB, image;
VideoCapture video1_testbench;
int camera_flag;

int record_flag;
int record_count;

//double rx,ry,rz,tx,ty,tz;
/*
struct tagsinfo
{
	int n;
	double pos[20][6];
} tags;
*/

FILE *outapril;

int tags_n;
double tags_pos[50][10];
int boxes_n;
double boxes_pos[50][10];

//////////////////////////////////////////////////////////////////////////////////
int testbench_init(int SystemWeight, int SystemHeight)
{
	//printf("init\n");
	L = luaL_newstate();
	luaL_openlibs(L);
	if ((luaL_loadfile(L,"../lua/func.lua")) || (lua_pcall(L,0,0,0)))
	//if ((luaL_loadfile(L,"../lua/func_fordata.lua")) || (lua_pcall(L,0,0,0)))
	{
		if ((luaL_loadfile(L,"../../lua/func.lua")) || (lua_pcall(L,0,0,0)))
		//if ((luaL_loadfile(L,"../../lua/func_fordata.lua")) || (lua_pcall(L,0,0,0)))
		//if ((luaL_loadfile(L,"../../lua/debugger.lua")) || (lua_pcall(L,0,0,0)))
			{printf("open lua file fail : %s\n",lua_tostring(L,-1));return -1;}
	}

	////////// apriltag initial ////////////////////////////////////////////////////
				// these might be needed
				//		m_cCameraMatrix(c_camera_matrix),
				//		m_cDistortionParameters(c_distortion_parameters) {
	m_psTagDetector = apriltag_detector_create();
		// not sure what does these means yet, just copied from Michael
	m_psTagDetector->quad_decimate = 1.0f;
	m_psTagDetector->quad_sigma = 0.0f;
	m_psTagDetector->nthreads = 1;
	m_psTagDetector->debug = 0;
	m_psTagDetector->refine_edges = 1;
	m_psTagDetector->refine_decode = 0;
	m_psTagDetector->refine_pose = 0;
		/* create the tag family */
	m_psTagFamily = tag36h11_create();
	m_psTagFamily->black_border = 1;
	apriltag_detector_add_family(m_psTagDetector, m_psTagFamily);

	camera_flag = 0;
	//record_flag = 1;

	if (camera_flag == 1)
	{
		video1_testbench.open(0);
		if (video1_testbench.isOpened())
			printf("video1 open successful\n");
		else
		{
			printf("video1 open failed\n");
			camera_flag = 0;
		}
	}

	if (record_flag == 1)
	{
		record_count = 0;
	}

	namedWindow("output",WINDOW_NORMAL);
	moveWindow("output",SystemWeight/2,0);
	resizeWindow("output",SystemWeight/2,SystemHeight/2);

	outapril = fopen("outapril.dat","w");

	return 0;
}

int testbench_step(char charFileName[])
{
	int i,j,k;
	int x_temp,y_temp;
	char c;

	//printf("%s\n",charFileName);
	//if (strcmp(charFileName,"camera") == 0)
	if (camera_flag == 1)
	{
		video1_testbench >> imageRGB;

		if (record_flag == 1)
		{
			record_count++;

			strcpy(fileNameBase,"../data/record/output_");
			Num2Str(record_count,fileNumber,8);
			strcpy(fileName,fileNameBase);
			strcat(fileName,fileNumber);
			strcat(fileName,fileExt);

			//printf("record %s\n",fileName);
			imwrite( fileName, imageRGB );
		}
	}
	else
	{
		imageRGB = cv::imread(charFileName, 1);
		if (!imageRGB.data)
		{
			printf("load image failed\n");
			return -1;
		}
	}

	//printf("step\n");

	//cin >> strFileName;
	//if(std::cin.good())
		//imageRGB = cv::imread(strFileName.c_str(), 1);
	//else
	//	return -1;

	/*
	string::size_type unPosStart = strFileName.find(strFileSuffix) + strFileSuffix.size();
	string::size_type unPosEnd = strFileName.find(strFileExtension);
	if(unPosStart == std::string::npos || unPosEnd == std::string::npos) {
		std::cerr << "could not find suffix/extension in file name: "<< strFileName << std::endl;
		return -1;
	}
	string strTimestamp = strFileName.substr(unPosStart, unPosEnd - unPosStart);
	*/

	//nTimestamp = std::stoi(strTimestamp);
	//printf("%d\n",nTimestamp);

	//printf("channels,%d ",image.channels());

					//printf("row and col,%d %d ",imageRGB.rows,imageRGB.cols);

	if ( !imageRGB.data ) { printf("Can't open image %s \n",charFileName); return -1; }
	cvtColor(imageRGB,image,CV_BGR2GRAY);

	/* convert image to apriltags format */
	image_u8_t* ptImageY = image_u8_create(image.cols, image.rows);
	// remember to destroy it
	for (unsigned int un_row = 0; un_row < ptImageY->height; un_row++) 
	{
		memcpy(&ptImageY->buf[un_row * ptImageY->stride],
					image.row(un_row).data,
					ptImageY->width);
	}
	//now ptImageY is the image_u8_t type image

	zarray_t* psDetections = apriltag_detector_detect(m_psTagDetector, ptImageY);
	image_u8_destroy(ptImageY);
	//now psDetections is an array of detected tags

	/////////  Trick Start  ///////////////////////

	/////////  Lua ///////////////////
		/*
		   		for every frame, build a taglist, which is a table, to lua
		   			taglist
					{
						timestamp = xxx
						n = <a number> the number of tags
						1 = <a table> which is a tag
							{
								center = {x = **, y = **}
								corner = <a table>
								{
									1 = {x = **, y = **}
									2
									3
									4
								}
							}
						2
						3
						4
						...
					}
		*/
	lua_settop(L,0);
	lua_getglobal(L,"func"); // stack 1 is the function
	//lua_getglobal(L,"debugger"); // stack 1 is the function
	lua_newtable(L);		 // stack 2 is the table (without a name)
	lua_pushstring(L,"timestamp");	// stack 3 is the index of timestamp
	lua_pushstring(L,"tobefilled");	// stack 4 is the value of timestamp
	lua_settable(L,2);
	lua_pushstring(L,"camera_flag");	// stack 3 is the index of timestamp
	lua_pushnumber(L,camera_flag);	// stack 4 is the value of timestamp
	lua_settable(L,2);
	lua_pushstring(L,"n");	// stack 3 is the index of n
	lua_pushnumber(L,zarray_size(psDetections));
	lua_settable(L,2);

	// go through all the tags

						//printf("tags: %d\n: ",zarray_size(psDetections));
	fprintf(outapril,"%d\n",zarray_size(psDetections));
	for (j = 0; j < zarray_size(psDetections); j++)
	{
		apriltag_detection_t *psDetection;
		zarray_get(psDetections, j, &psDetection);
		fprintf(outapril,"%f,%f\n",psDetection->c[1],psDetection->c[0]);
		fprintf(outapril,"%f,%f\n",psDetection->p[0][1],psDetection->p[0][0]);
		fprintf(outapril,"%f,%f\n",psDetection->p[1][1],psDetection->p[1][0]);
		fprintf(outapril,"%f,%f\n",psDetection->p[2][1],psDetection->p[2][0]);
		fprintf(outapril,"%f,%f\n",psDetection->p[3][1],psDetection->p[3][0]);
	}

	for (j = 0; j < zarray_size(psDetections); j++)
	{
		// for every tag : 
		apriltag_detection_t *psDetection;
		zarray_get(psDetections, j, &psDetection);

									//								 x
															////////////////////
															//				  //
															//				  //
									//					y	//				  //
															//				  //
															//				  //
															////////////////////

		////  output and draw
		////////// draw center /////////
		/*
		x_temp = psDetection->c[1];
		y_temp = psDetection->c[0];
		//printf("%d %d\n",x_temp, y_temp);
		//drawCross(imageRGB,x_temp,y_temp,"green");
		drawCross(imageRGB,x_temp,y_temp,"red");

		////////// draw corners /////////
		for (k = 0; k < 4; k++)
		{
			x_temp = psDetection->p[k][1];
			y_temp = psDetection->p[k][0];
			//drawCross(imageRGB,x_temp,y_temp,"blue");
			drawCross(imageRGB,x_temp,y_temp,"red");
		}
		*/

		/////////// Lua build table into stack ////////////////////////////
		lua_pushnumber(L,j+1);		//Stack 3 is the index of this tag
		lua_newtable(L);		 	// stack 4 is the table of this tag
			lua_pushstring(L,"id");		// stack 5 is the index of n
			lua_pushnumber(L,psDetection->id);		 	// stack 6 is the table of this center
		  lua_settable(L,4);
			lua_pushstring(L,"center");	// stack 5 is the index of n
			lua_newtable(L);		 	// stack 6 is the table of this center
				lua_pushstring(L,"x");	// stack 7 is the index of x
				lua_pushnumber(L,psDetection->c[1]);//Stack 8 is the value of x
			  lua_settable(L,6);

				lua_pushstring(L,"y");	// stack 7 is the index of y
				lua_pushnumber(L,psDetection->c[0]);//Stack 8 is the index of y
			  lua_settable(L,6);
		  lua_settable(L,4);

			lua_pushstring(L,"corners");	// stack 5 is index of corners
			lua_newtable(L);				// stack 6 is the table of the corners
				for (k = 0; k < 4; k++)
				{
					lua_pushnumber(L,k+1);	// stack 7 is the index of corner 1234
					lua_newtable(L);		// stack 8 is the table of corner 1234
						lua_pushstring(L,"x");	// stack 9 is the index of x
						lua_pushnumber(L,psDetection->p[k][1]);//Stack 10 is the value of x
			  		  lua_settable(L,8);
						lua_pushstring(L,"y");	// stack 9 is the index of x
						lua_pushnumber(L,psDetection->p[k][0]);//Stack 10 is the value of x
			  		  lua_settable(L,8);
			  	  lua_settable(L,6);
				}
		  lua_settable(L,4);	// add corners to table tag
		lua_settable(L,2);	// add tag to root table
	}

	//////////////// call lua function  /////////////////////////////////
													//printf("before pcak lua");
	//if (lua_pcall(L,1,1,0) != 0)	// one para, one return
	if (lua_pcall(L,1,1,0) != 0)	// one para, one return
		{printf("call func fail %s\n",lua_tostring(L,-1)); return -1;}

													//printf("after pcak lua");

	/////////////// lua take lua function result ///////////////////////
		// the result should be the structure of the blocks
	int n,label[50],boxlabel[50];
	int groupscale[50];
	double rx,ry,rz,tx,ty,tz,qx,qy,qz,qw;	// made global
	//printf("in C\n");
	if (lua_istable(L,1))
	{
		lua_pushstring(L,"tags");
		lua_gettable(L,-2);			//stack 2 now is the number n
									// add one layer below

		//////////////////////////////// tags ////////////////////////
		//printf("back is table\n");	// stack 1
		lua_pushstring(L,"n");		//stack 2
		lua_gettable(L,-2);			//stack 2 now is the number n
		n = (int)luaL_checknumber(L,-1);
		tags_n = n;
		//printf("number: %d\n",n);	//stack 2 now is the number n
		lua_pop(L,1);				// here goes stack 2

		// get every tags pos
		for (int i = 0; i < n; i++)
		{
			lua_pushnumber(L,i+1);		//stack 2
			lua_gettable(L,-2);			//stack 2 now is the table of {rota, tran}
				lua_pushstring(L,"rotation");		//stack 3
				lua_gettable(L,-2);			//stack 3 now is the table{x,y,z}
					lua_pushstring(L,"x");		//stack 4
					lua_gettable(L,-2);			//stack 4 now is the value
					rx = lua_tonumber(L,-1);
					lua_pop(L,1);			// here goes stack 4
					lua_pushstring(L,"y");		//stack 4
					lua_gettable(L,-2);			//stack 4 now is the value
					ry = lua_tonumber(L,-1);
					lua_pop(L,1);			// here goes stack 4
					lua_pushstring(L,"z");		//stack 4
					lua_gettable(L,-2);			//stack 4 now is the value
					rz = lua_tonumber(L,-1);
					lua_pop(L,1);			// here goes stack 4
				lua_pop(L,1);			// here goes stack 3

				lua_pushstring(L,"translation");		//stack 3
				lua_gettable(L,-2);			//stack 3 now is the table{x,y,z}
					lua_pushstring(L,"x");		//stack 4
					lua_gettable(L,-2);			//stack 4 now is the value
					tx = lua_tonumber(L,-1);
					lua_pop(L,1);			// here goes stack 4
					lua_pushstring(L,"y");		//stack 4
					lua_gettable(L,-2);			//stack 4 now is the value
					ty = lua_tonumber(L,-1);
					lua_pop(L,1);			// here goes stack 4
					lua_pushstring(L,"z");		//stack 4
					lua_gettable(L,-2);			//stack 4 now is the value
					tz = lua_tonumber(L,-1);
					lua_pop(L,1);			// here goes stack 4
				lua_pop(L,1);			// here goes stack 3

				lua_pushstring(L,"quaternion");		//stack 3
				lua_gettable(L,-2);			//stack 3 now is the table{v,w}
					lua_pushstring(L,"v");		//stack 3
					lua_gettable(L,-2);			//stack 3 now is the table{x,y,z}

						lua_pushstring(L,"x");		//stack 4
						lua_gettable(L,-2);			//stack 4 now is the value
						qx = lua_tonumber(L,-1);
						lua_pop(L,1);			// here goes stack 4
						lua_pushstring(L,"y");		//stack 4
						lua_gettable(L,-2);			//stack 4 now is the value
						qy = lua_tonumber(L,-1);
						lua_pop(L,1);			// here goes stack 4
						lua_pushstring(L,"z");		//stack 4
						lua_gettable(L,-2);			//stack 4 now is the value
						qz = lua_tonumber(L,-1);
						lua_pop(L,1);			// here goes stack 4
					lua_pop(L,1);			// here goes stack 4

					lua_pushstring(L,"w");		//stack 4
					lua_gettable(L,-2);			//stack 4 now is the value
					qw = lua_tonumber(L,-1);
					lua_pop(L,1);			// here goes stack 4
				lua_pop(L,1);			// here goes stack 3

				lua_pushstring(L,"label");	
				lua_gettable(L,-2);	
				label[i] = lua_tonumber(L,-1);
				lua_pop(L,1);			// here goes stack 3
			lua_pop(L,1);				// goes stack 2

			tags_pos[i][0] = rx;
			tags_pos[i][1] = ry;
			tags_pos[i][2] = rz;
			tags_pos[i][3] = tx;
			tags_pos[i][4] = ty;
			tags_pos[i][5] = tz;
			tags_pos[i][6] = qx;
			tags_pos[i][7] = qy;
			tags_pos[i][8] = qz;
			tags_pos[i][9] = qw;
			/*
			printf("ros x:%lf\n",rx);
			printf("ros y:%lf\n",ry);
			printf("ros z:%lf\n",rz);
			printf("tra x:%lf\n",tx);
			printf("tra y:%lf\n",ty);
			printf("tra z:%lf\n",tz);
			*/
		}	// end of for i for tags
		lua_pop(L,1);			// here goes stack 2

									//printf("after retrieve box information");
		//////////////////////////////// boxes ////////////////////////
		lua_pushstring(L,"boxes");
		lua_gettable(L,-2);			//stack 2 now is the string boxes

		lua_pushstring(L,"n");		//stack 2 + 1
		lua_gettable(L,-2);			//stack 2+1 now is the number n
		n = (int)luaL_checknumber(L,-1);
		boxes_n = n;
		lua_pop(L,1);				// here goes stack 2+1
									// add one layer below

		/// iteration boxes ////
		// get every boxes pos
		for (int i = 0; i < n; i++)
		{
			lua_pushnumber(L,i+1);		//stack 2 + 1
			lua_gettable(L,-2);			//stack 2 now is the table of {rota, tran}
				lua_pushstring(L,"rotation");		//stack 3
				lua_gettable(L,-2);			//stack 3 now is the table{x,y,z}
					lua_pushstring(L,"x");		//stack 4
					lua_gettable(L,-2);			//stack 4 now is the value
					rx = lua_tonumber(L,-1);
					lua_pop(L,1);			// here goes stack 4
					lua_pushstring(L,"y");		//stack 4
					lua_gettable(L,-2);			//stack 4 now is the value
					ry = lua_tonumber(L,-1);
					lua_pop(L,1);			// here goes stack 4
					lua_pushstring(L,"z");		//stack 4
					lua_gettable(L,-2);			//stack 4 now is the value
					rz = lua_tonumber(L,-1);
					lua_pop(L,1);			// here goes stack 4
				lua_pop(L,1);			// here goes stack 3

				lua_pushstring(L,"translation");		//stack 3
				lua_gettable(L,-2);			//stack 3 now is the table{x,y,z}
					lua_pushstring(L,"x");		//stack 4
					lua_gettable(L,-2);			//stack 4 now is the value
					tx = lua_tonumber(L,-1);
					lua_pop(L,1);			// here goes stack 4
					lua_pushstring(L,"y");		//stack 4
					lua_gettable(L,-2);			//stack 4 now is the value
					ty = lua_tonumber(L,-1);
					lua_pop(L,1);			// here goes stack 4
					lua_pushstring(L,"z");		//stack 4
					lua_gettable(L,-2);			//stack 4 now is the value
					tz = lua_tonumber(L,-1);
					lua_pop(L,1);			// here goes stack 4
				lua_pop(L,1);			// here goes stack 3

				lua_pushstring(L,"quaternion");		//stack 3
				lua_gettable(L,-2);			//stack 3 now is the table{x,y,z}
					lua_pushstring(L,"v");		//stack 3
					lua_gettable(L,-2);			//stack 3 now is the table{x,y,z}

						lua_pushstring(L,"x");		//stack 4
						lua_gettable(L,-2);			//stack 4 now is the value
						qx = lua_tonumber(L,-1);
						lua_pop(L,1);			// here goes stack 4
						lua_pushstring(L,"y");		//stack 4
						lua_gettable(L,-2);			//stack 4 now is the value
						qy = lua_tonumber(L,-1);
						lua_pop(L,1);			// here goes stack 4
						lua_pushstring(L,"z");		//stack 4
						lua_gettable(L,-2);			//stack 4 now is the value
						qz = lua_tonumber(L,-1);
						lua_pop(L,1);			// here goes stack 4

					lua_pop(L,1);			// here goes stack 4

					lua_pushstring(L,"w");		//stack 4
					lua_gettable(L,-2);			//stack 4 now is the value
					qw = lua_tonumber(L,-1);
					lua_pop(L,1);			// here goes stack 4
				lua_pop(L,1);			// here goes stack 3

				lua_pushstring(L,"label");	
				lua_gettable(L,-2);	
				boxlabel[i] = lua_tonumber(L,-1);
				lua_pop(L,1);			// here goes stack 3

				lua_pushstring(L,"groupscale");	
				lua_gettable(L,-2);	
				groupscale[i] = lua_tonumber(L,-1);
				lua_pop(L,1);			// here goes stack 3

			lua_pop(L,1);				// goes stack 2


			boxes_pos[i][0] = rx;
			boxes_pos[i][1] = ry;
			boxes_pos[i][2] = rz;
			boxes_pos[i][3] = tx;
			boxes_pos[i][4] = ty;
			boxes_pos[i][5] = tz;
			boxes_pos[i][6] = qx;
			boxes_pos[i][7] = qy;
			boxes_pos[i][8] = qz;
			boxes_pos[i][9] = qw;

		}	// end of for i for boxes

												//printf("after retrieve tags information\n");
	}

	////////////// draw something on the image ////////////////
	cv::Matx31d RotationVector;
	cv::Matx31d TranslationVector;
	double rotationscale;
	double axisth,axisx,axisy,axisz;

	std::vector<cv::Point3d> m_vecOriginPts;
	m_vecOriginPts.push_back(cv::Point3d(0.0f,0.0f, 0.0f));

	double m_fFx = 8.8396142504070610e+02;
	double m_fFy = 8.8396142504070610e+02;
	// camera principal point 
	double m_fPx = 3.1950000000000000e+02;
	double m_fPy = 1.7950000000000000e+02;
	// camera distortion coefficients
	double m_fK1 = 1.8433447851104852e-02;
	double m_fK2 = 1.6727474183089033e-01;
	double m_fK3 = -1.5480889084966631e+00;

	if (camera_flag != 1)
	{
		m_fFx = 8.8396142504070610e+02;
		m_fFy = 8.8396142504070610e+02;
		// camera principal point 
		m_fPx = 3.1950000000000000e+02;
		m_fPy = 1.7950000000000000e+02;
		// camera distortion coefficients
		m_fK1 = 1.8433447851104852e-02;
		m_fK2 = 1.6727474183089033e-01;
		m_fK3 = -1.5480889084966631e+00;
	}
	else
	{
		m_fFx = 939.001439;
		m_fFy = 939.001439;
		// camera principal point
		m_fPx = 320;
		m_fPy = 240;
		// camera distortion coefficients
		m_fK1 = -0.4117914;
		m_fK2 = 5.17498964;
		m_fK3 = -17.7026842;
	}
	//*/

	/* camera matrix */
	const cv::Matx<double, 3, 3> cCameraMatrix =
			cv::Matx<double, 3, 3>(	m_fFx, 0.0f, m_fPx,
									0.0f, m_fFy, m_fPy,
									0.0f,  0.0f,  1.0f);
	/* camera distortion parameters */
	const cv::Matx<double, 5, 1> cDistortionParameters =
		//cv::Matx<double, 5, 1>(m_fK1, m_fK2, 0.0f, 0.0f, m_fK3);
		cv::Matx<double, 5, 1>(0.0f, 0.0f, 0.0f, 0.0f, 0.0f);
	std::vector<cv::Point2d> vecBlockCentrePixel;

	char colour[10];

	for (j = 0; j < zarray_size(psDetections); j++)
	//for (j = 0; j < tags_n; j++)
	{
		// draw 2D point detected, using psDetections
		apriltag_detection_t *psDetection;
		zarray_get(psDetections, j, &psDetection);
		////  output and draw
		////////// draw center /////////
		x_temp = psDetection->c[1];
		y_temp = psDetection->c[0];
		//printf("%d %d\n",x_temp, y_temp);
		//drawCross(imageRGB,x_temp,y_temp,"green");

		//drawCross(imageRGB,x_temp,y_temp,"red");

		////////// draw corners /////////
		for (k = 0; k < 4; k++)
		{
			x_temp = psDetection->p[k][1];
			y_temp = psDetection->p[k][0];
			//drawCross(imageRGB,x_temp,y_temp,"blue");
			if (k == 0)
				drawCross(imageRGB,x_temp,y_temp,"blue");
			if (k == 1)
				drawCross(imageRGB,x_temp,y_temp,"blue");
			if (k == 2)
				drawCross(imageRGB,x_temp,y_temp,"blue");
			if (k == 3)
				drawCross(imageRGB,x_temp,y_temp,"blue");
		}
	}

											//printf("before projection");

	// draw center of tags
	for (j = 0; j < tags_n; j++)
	{
		//printf("label[%d] = %d\n",j,label[j]);
		if (label[j] % 3 == 0) strcpy(colour,"red");
		if (label[j] % 3 == 1) strcpy(colour,"green");
		if (label[j] % 3 == 2) strcpy(colour,"blue");
		// draw 3D point, using boxes_pos and tags_pos
		// left and right hand using opencv
		TranslationVector = cv::Matx31d( -tags_pos[j][3], tags_pos[j][4], tags_pos[j][5]);
		qx = tags_pos[j][6];
		qy = tags_pos[j][7];
		qz = tags_pos[j][8];
		qw = tags_pos[j][9];

		axisth = 2 * acos(qw);
		axisx = qx / sin(axisth/2);
		axisy = qy / sin(axisth/2);
		axisz = qz / sin(axisth/2);

		rotationscale = sqrt(axisx*axisx+axisy*axisy+axisz*axisz) / axisth;
		axisx = axisx / rotationscale;
		axisy = axisy / rotationscale;
		axisz = axisz / rotationscale;
		RotationVector = cv::Matx31d( axisx, -axisy, -axisz);

		cv::projectPoints(	m_vecOriginPts,
							RotationVector,
							TranslationVector,
							cCameraMatrix,
							cDistortionParameters,
							vecBlockCentrePixel);
		//printf("%lf %lf\n",vecBlockCentrePixel[0].x, vecBlockCentrePixel[0].y);
		
		//drawCross(imageRGB,(int)vecBlockCentrePixel[0].x,(int)vecBlockCentrePixel[0].y,colour,label[j]);
		drawCross(imageRGB,(int)vecBlockCentrePixel[0].x,(int)vecBlockCentrePixel[0].y,"green",label[j]);
	}

	double halfBox = 0.0275;
	char framecolor[20] = "blue";
	char tempstr[20];
	std::vector<cv::Point3d> m_vecOriginPts_box;
	m_vecOriginPts_box.push_back(cv::Point3d(0.0f,0.0f, 0.0f));
	m_vecOriginPts_box.push_back(cv::Point3d( halfBox, halfBox, halfBox));
	m_vecOriginPts_box.push_back(cv::Point3d( halfBox,-halfBox, halfBox));
	m_vecOriginPts_box.push_back(cv::Point3d(-halfBox,-halfBox, halfBox));
	m_vecOriginPts_box.push_back(cv::Point3d(-halfBox, halfBox, halfBox));
	m_vecOriginPts_box.push_back(cv::Point3d( halfBox, halfBox,-halfBox));
	m_vecOriginPts_box.push_back(cv::Point3d( halfBox,-halfBox,-halfBox));
	m_vecOriginPts_box.push_back(cv::Point3d(-halfBox,-halfBox,-halfBox));
	m_vecOriginPts_box.push_back(cv::Point3d(-halfBox, halfBox,-halfBox));

	// draw center of boxes
	for (j = 0; j < boxes_n; j++)
	{
		//printf("label[%d] = %d\n",j,label[j]);
		if (label[j] % 3 == 0) strcpy(colour,"red");
		if (label[j] % 3 == 1) strcpy(colour,"green");
		if (label[j] % 3 == 2) strcpy(colour,"blue");
		// draw 3D point, using boxes_pos and boxes_pos
		// left and right hand using opencv
		TranslationVector = cv::Matx31d( -boxes_pos[j][3], boxes_pos[j][4], boxes_pos[j][5]);
		qx = boxes_pos[j][6];
		qy = boxes_pos[j][7];
		qz = boxes_pos[j][8];
		qw = boxes_pos[j][9];

		axisth = 2 * acos(qw);
		axisx = qx / sin(axisth/2);
		axisy = qy / sin(axisth/2);
		axisz = qz / sin(axisth/2);

		rotationscale = sqrt(axisx*axisx+axisy*axisy+axisz*axisz) / axisth;
		axisx = axisx / rotationscale;
		axisy = axisy / rotationscale;
		axisz = axisz / rotationscale;

		RotationVector = cv::Matx31d( axisx, -axisy, -axisz);

		cv::projectPoints(	m_vecOriginPts_box,
							RotationVector,
							TranslationVector,
							cCameraMatrix,
							cDistortionParameters,
							vecBlockCentrePixel);
		
		//drawCross(imageRGB,(int)vecBlockCentrePixel[0].x,(int)vecBlockCentrePixel[0].y,colour,label[j]);
		//printf("before draw box\n");
		//for (i = 1; i <= 8; i++)
		//	drawCross(imageRGB,(int)vecBlockCentrePixel[i].x,(int)vecBlockCentrePixel[i].y,"red");
		if (groupscale[j] == 1) strcpy(framecolor,"green");
						   else strcpy(framecolor,"blue");
		for (i = 1; i <=3; i++)
		{
			drawLine(imageRGB,(int)vecBlockCentrePixel[i].x,(int)vecBlockCentrePixel[i].y,
							  (int)vecBlockCentrePixel[i+1].x,(int)vecBlockCentrePixel[i+1].y,framecolor);
			drawLine(imageRGB,(int)vecBlockCentrePixel[i+4].x,(int)vecBlockCentrePixel[i+4].y,
							  (int)vecBlockCentrePixel[i+5].x,(int)vecBlockCentrePixel[i+5].y,framecolor);
		}
		drawLine(imageRGB,(int)vecBlockCentrePixel[4].x,(int)vecBlockCentrePixel[4].y,
						  (int)vecBlockCentrePixel[1].x,(int)vecBlockCentrePixel[1].y,framecolor);
		drawLine(imageRGB,(int)vecBlockCentrePixel[8].x,(int)vecBlockCentrePixel[8].y,
						  (int)vecBlockCentrePixel[5].x,(int)vecBlockCentrePixel[5].y,framecolor);


		for (i = 1; i <=4; i++)
			drawLine(imageRGB,(int)vecBlockCentrePixel[i].x,(int)vecBlockCentrePixel[i].y,
							  (int)vecBlockCentrePixel[i+4].x,(int)vecBlockCentrePixel[i+4].y,framecolor);

		//drawCross(imageRGB,(int)vecBlockCentrePixel[0].x,(int)vecBlockCentrePixel[0].y,"red",boxlabel[j]);
		Num2Str(boxlabel[j],tempstr,2);
		drawString(imageRGB,(int)vecBlockCentrePixel[0].x,(int)vecBlockCentrePixel[0].y,tempstr,"red");
	}

													//printf("after projection\n");

	////////////// show image and next frame //////////////////
	imshow("output", imageRGB);
													//printf("after imshow\n");
	waitKey(30);
	//c = waitKey(0);

	return 0;
}

int testbench_close()
{
	//printf("close\n");
	fclose(outapril);
	cvDestroyWindow("output");
	lua_close(L);
	return 0;
}

//////////////////////////////////////////////////////////////////////

int Num2Str(int x, char str[], int length)
{
	int y,i = length;
	y = x;

	str[i] = '\0';
	for (i = length-1; i >=0; i--)
	{
		str[i] = y % 10 + '0';
		y = y / 10;
	}

	return 0;
}


///////  OpenCV draw  ////////////////////////////////////////////////

int drawString(Mat img, int x, int y, char str[], const char color[])
{
	int R,G,B;
	if (strcmp(color,"blue") == 0)
	{ R = 0; G = 0; B = 255; }
	else if (strcmp(color,"green") == 0)
	{ R = 0; G = 255; B = 0; }
	else if (strcmp(color,"red") == 0)
	{ R = 255; G = 0; B = 0; }

	CvFont font;    
    double hScale=1;   
    double vScale=1;    
    int lineWidth=2;

	//cvInitFont(&font,CV_FONT_HERSHEY_SIMPLEX|CV_FONT_ITALIC, hScale,vScale,0,lineWidth);
	putText(img,str,Point(y,x),CV_FONT_HERSHEY_SIMPLEX,0.6,CV_RGB(R,G,B));
	return 0;
}

int drawLine(Mat img, int x1, int y1, int x2, int y2, const char colour[])
{
	double k; 
	double b;
	int start,end;
	int i,j;

	if ((abs(x2 - x1) > abs(y2 - y1)) && (x2 - x1 != 0))
	{
		k = 1.0 * (y2 - y1) / (x2 - x1);
		b = y1 - x1 * k;
		if (x1 < x2) 
		{	
			start = x1;
			end = x2;
		}
		else
		{
			start = x2;
			end = x1;
		}
		for (i = start; i <= end; i++)
		{
			j = (int)(i * k + b);
			//drawCross(img,i,j,colour);
			drawPoint(img,i,j,colour);
		}
	}
	else if (y2 - y1 != 0)
	{
		k = 1.0 * (x2 - x1) / (y2 - y1);
		b = x1 - y1 * k;
		if (y1 < y2) 
		{	
			start = y1;
			end = y2;
		}
		else
		{
			start = y2;
			end = y1;
		}
		for (j = start; j <= end; j++)
		{
			i = (int)(j * k + b);
			//drawCross(img,i,j,colour);
			drawPoint(img,i,j,colour);
		}
	}
	return 0;
}

int drawCross(Mat img, int x, int y, const char colour[],int label)
{
	label = label % 9;
	if (label == 0) label = 9;
	if (label == 1)
		drawCross(imageRGB,x,y,colour);
	else if (label == 2)
	{
		drawCross(imageRGB,x,y-2,colour);
		drawCross(imageRGB,x,y+2,colour);
	}
	else if (label == 3)
	{
		drawCross(imageRGB,x-2,y-2,colour);
		drawCross(imageRGB,x-2,y+2,colour);
		drawCross(imageRGB,x+2,y,colour);
	}
	else if (label == 4)
	{
		drawCross(imageRGB,x-2,y-2,colour);
		drawCross(imageRGB,x-2,y+2,colour);
		drawCross(imageRGB,x+2,y-2,colour);
		drawCross(imageRGB,x+2,y+2,colour);
	}
	else if (label == 5)
	{
		drawCross(imageRGB,x-6,y-2,colour);
		drawCross(imageRGB,x-2,y-2,colour);
		drawCross(imageRGB,x-2,y+2,colour);
		drawCross(imageRGB,x+2,y-2,colour);
		drawCross(imageRGB,x+2,y+2,colour);
	}
	else if (label == 6)
	{
		drawCross(imageRGB,x-6,y-2,colour);
		drawCross(imageRGB,x-6,y+2,colour);
		drawCross(imageRGB,x-2,y-2,colour);
		drawCross(imageRGB,x-2,y+2,colour);
		drawCross(imageRGB,x+2,y-2,colour);
		drawCross(imageRGB,x+2,y+2,colour);
	}
	else if (label == 7)
	{
		drawCross(imageRGB,x-6,y-2,colour);
		drawCross(imageRGB,x-6,y+2,colour);
		drawCross(imageRGB,x-2,y-2,colour);
		drawCross(imageRGB,x-2,y+2,colour);
		drawCross(imageRGB,x+2,y-2,colour);
		drawCross(imageRGB,x+2,y+2,colour);
		drawCross(imageRGB,x+6,y-2,colour);
	}
	else if (label == 8)
	{
		drawCross(imageRGB,x-6,y-2,colour);
		drawCross(imageRGB,x-6,y+2,colour);
		drawCross(imageRGB,x-2,y-2,colour);
		drawCross(imageRGB,x-2,y+2,colour);
		drawCross(imageRGB,x+2,y-2,colour);
		drawCross(imageRGB,x+2,y+2,colour);
		drawCross(imageRGB,x+6,y-2,colour);
		drawCross(imageRGB,x+6,y+2,colour);
	}
	else if (label == 9)
	{
		drawCross(imageRGB,x,y,colour);
		drawCross(imageRGB,x-4,y,colour);
		drawCross(imageRGB,x+4,y,colour);

		drawCross(imageRGB,x,  y-4,colour);
		drawCross(imageRGB,x-4,y-4,colour);
		drawCross(imageRGB,x+4,y-4,colour);

		drawCross(imageRGB,x,  y+4,colour);
		drawCross(imageRGB,x-4,y+4,colour);
		drawCross(imageRGB,x+4,y+4,colour);
	}
	return 0;
}

int drawCross(Mat img, int x, int y, const char color[])
{
	if ((x > img.rows-1) || (x < 0) || (y > img.cols-1) || (y < 0)) return -1;

	int R,G,B;
	if (strcmp(color,"blue") == 0)
	{ R = 0; G = 0; B = 255; }
	else if (strcmp(color,"green") == 0)
	{ R = 0; G = 255; B = 0; }
	else if (strcmp(color,"red") == 0)
	{ R = 255; G = 0; B = 0; }
	Mat_<Vec3b> _image = img;
	setColor(_image(x,y),R,G,B);
	if (x != 0) 			setColor(_image(x-1,y),R,G,B);
	if (x != img.rows-1) 	setColor(_image(x+1,y),R,G,B);
	if (y != 0) 			setColor(_image(x,y-1),R,G,B);
	if (y != img.cols-1) 	setColor(_image(x,y+1),R,G,B);
	img = _image;
	return 0;
}

int drawPoint(Mat img, int x, int y, const char color[])
{
	if ((x > img.rows-1) || (x < 0) || (y > img.cols-1) || (y < 0)) return -1;

	int R,G,B;
	if (strcmp(color,"blue") == 0)
	{ R = 0; G = 0; B = 255; }
	else if (strcmp(color,"green") == 0)
	{ R = 0; G = 255; B = 0; }
	else if (strcmp(color,"red") == 0)
	{ R = 255; G = 0; B = 0; }
	Mat_<Vec3b> _image = img;
	setColor(_image(x,y),R,G,B);
	img = _image;
	return 0;
}

int setColor(cv::Vec<unsigned char, 3> &pix,int R,int G, int B)
{
	pix[0] = B;
	pix[1] = G;
	pix[2] = R;
	return 0;
}

////////  Number to String  /////////////////////////////////////////////////////////
char* numberToString(int n, int k, char str[])
{
	int i;
	int tens;
												// take 5 as an example
	tens = 1;
	for (i = 0; i < k; i++)
		tens *= 10;
												// tens = 100000
	n = n % tens;
	tens /= 10;

	for (i = 0; i < k; i++)						//5 times
	{
		str[i] = n / tens + '0' - 0;
		n = n % tens;
		tens /= 10;
	}

	str[k] = '\0';

	return str;
}

char* numberToString5(int n, char str[])
{
	numberToString(n,5,str);
	return 0;
}
