cmake_minimum_required(VERSION 3.16)
include(${CMAKE_CURRENT_LIST_DIR}/cpp.cmake)

if(NOT DEFINED install_dir)
	set(install_dir libs)
endif()

macro(do_project)
	do_cpp_project()
endmacro()


macro(do_src)
	cpp_pre_target()

	add_library(${PROJECT_NAME} STATIC ${input_files})

	install(TARGETS ${PROJECT_NAME}
			ARCHIVE DESTINATION ${install_dir})

	cpp_post_target()
endmacro()
