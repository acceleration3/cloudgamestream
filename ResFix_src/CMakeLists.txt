cmake_minimum_required(VERSION 3.15)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

project(ResFix)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

find_package(NVAPI)

if (NOT NVAPI_FOUND)
    message(FATAL_ERROR "NVAPI was not found. Read the file nvapi_info.txt inside the nvapi folder for more information.")
endif()

add_executable(ResFix main.cpp)
target_include_directories(ResFix PRIVATE ${NVAPI_INCLUDE_DIR})
target_link_libraries(ResFix ${NVAPI_LIBRARY})