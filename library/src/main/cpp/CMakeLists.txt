# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(myNpmLib)
#set(CMAKE_CXX_STANDARD 17 CACHE STRING "The C++ version to be used.")

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})
#set(CMAKE_CXX_FLAGS "-D__OHOS__=1")
if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(${NATIVERENDER_ROOT_PATH}
                    ${NATIVERENDER_ROOT_PATH}/include)

add_library(library SHARED napi_init.cpp
wave-reader.cc
vad.cc
non-streaming-asr.cc
streaming-asr.cc
)

add_library(sherpa_onnx_c_api SHARED IMPORTED)
set_target_properties(sherpa_onnx_c_api
    PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/${OHOS_ARCH}/libsherpa-onnx-c-api.so)

add_library(onnxruntime SHARED IMPORTED)
set_target_properties(onnxruntime
    PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libs/${OHOS_ARCH}/libonnxruntime.so)

target_link_libraries(library PUBLIC libace_napi.z.so
 libhilog_ndk.z.so # for hilog
 librawfile.z.so
sherpa_onnx_c_api onnxruntime)
#target_link_libraries(library PUBLIC libace_napi.z.so)
