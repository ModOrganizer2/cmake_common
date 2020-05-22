cmake_minimum_required(VERSION 3.16)
include(${CMAKE_CURRENT_LIST_DIR}/functions.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cpp.cmake)

if(NOT DEFINED install_dir)
	if(${PROJECT_NAME} STREQUAL "uibase")
		set(install_dir bin)
	else()
		set(install_dir bin/dlls)
	endif()
endif()

macro(do_project)
	do_cpp_project()
endmacro()

macro(do_src)
	cpp_pre_target()

	add_library(${PROJECT_NAME} SHARED ${input_files})

	install(TARGETS ${PROJECT_NAME}
			RUNTIME DESTINATION ${install_dir}
			ARCHIVE DESTINATION libs)

	install(FILES $<TARGET_PDB_FILE:${PROJECT_NAME}>
			DESTINATION pdb)

	set_project_to_run_from_install(ModOrganizer)
	cpp_post_target()
endmacro()
