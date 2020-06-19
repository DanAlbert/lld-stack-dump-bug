cmake_minimum_required(VERSION 3.10)

project(application)
if(ANDROID_LD STREQUAL lld)
  set(SUFFIX -lld)
else()
  set(SUFFIX "")
endif()
add_executable("application${SUFFIX}" application.cpp)
