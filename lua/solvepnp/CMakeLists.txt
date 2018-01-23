cmake_minimum_required(VERSION 2.8)
project( solvepnp )

#============================================================================
# OpenCV
#============================================================================
find_package( OpenCV REQUIRED )
#============================================================================
# OpenCV
#============================================================================
find_package( Lua REQUIRED )
#${LUA_INCLUDE_DIR}
#${LUA_LIBRARIES}

include_directories( ${OpenCV_INCLUDE_DIRS} ${LUA_INCLUDE_DIR})
#add_executable( solvepnp solvepnp.cpp )
add_library( solvepnp SHARED solvepnp.cpp )
target_link_libraries( solvepnp ${OpenCV_LIBS} ${LUA_LIBRARIES})
