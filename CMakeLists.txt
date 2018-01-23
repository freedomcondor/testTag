cmake_minimum_required(VERSION 2.8)
project( luaTag )

#============================================================================
# OpenCV
#============================================================================
find_package( OpenCV REQUIRED )
#${OpenCV_INCLUDE_DIRS}
#${OpenCV_LIBS}

#============================================================================
# Lua
#============================================================================
find_package( Lua REQUIRED )
#${LUA_INCLUDE_DIR}
#${LUA_LIBRARIES}

include_directories( 	${OpenCV_INCLUDE_DIRS} 
						${LUA_INCLUDE_DIR}
					)

set(CMAKE_BUILD_TYPE Debug)

add_executable( luaTag
					testbench/main.cpp 
					testbench/testbench.cpp
		)
target_link_libraries( luaTag ${OpenCV_LIBS} 
								${LUA_LIBRARIES}
					)
