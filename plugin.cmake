cmake_minimum_required(VERSION 3.16)

add_library(${CMAKE_PROJECT_NAME} SHARED ${input_files})
target_link_libraries(${CMAKE_PROJECT_NAME} uibase)

install(TARGETS ${CMAKE_PROJECT_NAME} RUNTIME DESTINATION bin/plugins)
install(FILES $<TARGET_PDB_FILE:${CMAKE_PROJECT_NAME}> DESTINATION pdb)
