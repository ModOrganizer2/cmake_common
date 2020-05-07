cmake_minimum_required(VERSION 3.16)
include(${CMAKE_CURRENT_LIST_DIR}/cpp.cmake)


macro(do_project)
	do_cpp_project()
endmacro()


macro(do_src)
	cpp_pre_target()

	add_executable(${PROJECT_NAME} ${input_files})

	set_property(TARGET ${PROJECT_NAME} PROPERTY
  		MSVC_RUNTIME_LIBRARY "MultiThreaded")

	if(DEFINED executable_name)
		set_target_properties(${PROJECT_NAME} PROPERTIES
			OUTPUT_NAME ${executable_name})
	endif()

	requires_library(gtest)
	cpp_post_target()

endmacro()
