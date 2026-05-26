cmake_minimum_required(VERSION 2.6)
project(otclient)

# define framework options
set(FRAMEWORK_SOUND ON)
set(FRAMEWORK_GRAPHICS ON)
set(FRAMEWORK_NET ON)
set(FRAMEWORK_XML ON)

add_subdirectory(src)
