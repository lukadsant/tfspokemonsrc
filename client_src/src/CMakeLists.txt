# include framework
include(${CMAKE_CURRENT_LIST_DIR}/framework/CMakeLists.txt)

# include client
include(${CMAKE_CURRENT_LIST_DIR}/client/CMakeLists.txt)

# target
add_executable(${PROJECT_NAME}
    ${CMAKE_CURRENT_LIST_DIR}/main.cpp
    ${framework_SOURCES}
    ${client_SOURCES}
)

target_link_libraries(${PROJECT_NAME} ${framework_LIBRARIES})

add_definitions(-DVERSION="0.6.3")
