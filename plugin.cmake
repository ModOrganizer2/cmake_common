cmake_minimum_required(VERSION 3.16)
include(${CMAKE_CURRENT_LIST_DIR}/functions.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cpp.cmake)

if(NOT DEFINED install_dir)
	set(install_dir bin/plugins)
endif()

macro(do_project)
	do_cpp_project()
endmacro()

macro(do_src)
	cpp_pre_target()

	add_library(${PROJECT_NAME} SHARED ${input_files})
	target_link_libraries(${PROJECT_NAME} uibase)

	set_project_to_run_from_install(ModOrganizer)
	cpp_post_target()

	install(TARGETS ${PROJECT_NAME} RUNTIME DESTINATION ${install_dir})
	install(FILES $<TARGET_PDB_FILE:${PROJECT_NAME}> DESTINATION pdb)
endmacro()
