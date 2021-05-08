set(NVAPI_FOUND 0)

if(WIN32)
    find_path(NVAPI_INCLUDE_DIR
        NAMES nvapi.h
        PATHS ${CMAKE_SOURCE_DIR}/nvapi
    )

    if("${CMAKE_SIZEOF_VOID_P}" EQUAL 8)
        message("Trying to find AMD64 NVAPI library...")
        set(NVAPI_ARCH_DIR amd64)
        set(NVAPI_LIBRARY_NAME nvapi64)
    else()
        message("Trying to find x86 NVAPI library...")
        set(NVAPI_ARCH_DIR x86)
        set(NVAPI_LIBRARY_NAME nvapi)
    endif()

    set(NVAPI_POSSIBLE_LIBRARY_PATHS
        ${NVAPI_INCLUDE_DIR}/${NVAPI_ARCH_DIR}
    )

    find_library(NVAPI_LIBRARY
        NAMES ${NVAPI_LIBRARY_NAME}
        HINTS ${NVAPI_POSSIBLE_LIBRARY_PATHS} 
    )

    message("NVAPI_INCLUDE_DIR: ${NVAPI_INCLUDE_DIR}")
    message("NVAPI_LIBRARY: ${NVAPI_LIBRARY}")

    if(NVAPI_INCLUDE_DIR AND NVAPI_LIBRARY)
        message("Found NVAPI.")
        set(NVAPI_FOUND 1)
    endif()
endif()