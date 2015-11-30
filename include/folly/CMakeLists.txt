file(GLOB_RECURSE Folly_SOURCES "*.cpp")
file(GLOB_RECURSE Folly_HEADERS "*.h")

set (Folly_INCLUDE_DIRS "")
foreach (_headerFile ${Folly_HEADERS})
    get_filename_component(_dir ${_headerFile} PATH)
    list (APPEND Folly_INCLUDE_DIRS ${_dir})
endforeach()
list(REMOVE_DUPLICATES Folly_INCLUDE_DIRS)

include_directories(${Folly_INCLUDE_DIRS})

# library sources:
#list(APPEND LIB_SRCS
#     Conv.cpp
#     FileUtil.cpp 
#     String.cpp 
#     SpookyHashV1.cpp 
#     SpookyHashV2.cpp 
#     Malloc.cpp
#)

# Create a library which includes the source file ".cpp".
# The extension is already found. Any number of sources could be listed here.
add_library(${PACKAGE_NAME} SHARED ${Folly_SOURCES})

install(TARGETS ${PACKAGE_NAME} LIBRARY DESTINATION lib)
