cmake_minimum_required(VERSION 3.16)
include(${CMAKE_CURRENT_LIST_DIR}/python.cmake)

if(NOT DEFINED install_dir)
	set(install_dir bin/plugins)
endif()


macro(do_project)
	do_python_project()
endmacro()


# sets `var` to TRUE if the given directory should be installed
#
function(is_interesting_python_dir var dir)
	file(GLOB_RECURSE dir_content "${dir}/*.py")

	if("X${dir_content}" STREQUAL "X")
		set(${var} FALSE PARENT_SCOPE)
	else()
		set(${var} TRUE PARENT_SCOPE)
	endif()
endfunction()


macro(do_src)
	# this copies all the .py files that are directly in src/ into
	# ${install_dir}/
	#
	# any folder that contains at least one .py file (recursive) is copied in
	# bin/plugins/data


	# everything in the src directory
	file(GLOB everything ${CMAKE_SOURCE_DIR}/src/*)

	foreach(object ${everything})
		if(IS_DIRECTORY "${object}")
			# only copy interesting directories
			is_interesting_python_dir(is_interesting "${object}")
			if (${is_interesting})
				list(APPEND data_dirs "${object}")
			endif()
		else()
			get_filename_component(ext "${object}" LAST_EXT)

			if("${ext}" STREQUAL ".py")
				# copy .py files directly
				list(APPEND src_files "${object}")
			elseif("${ext}" STREQUAL ".ui")
				# process .ui files and copy the resulting .py in data
				get_filename_component(name "${object}" NAME_WLE)
				set(output "${CMAKE_CURRENT_BINARY_DIR}/${name}.py")

				execute_process(
					COMMAND ${PYTHON_ROOT}/PCbuild/amd64/python.exe
						-I
						-m PyQt6.uic.pyuic
						-o "${output}"
						"${object}"
					WORKING_DIRECTORY ${PYTHON_ROOT})

				list(APPEND data_files "${output}")
#			elseif("${ext}" STREQUAL ".qrc")
#				# process .qrc files and copy the resulting .py in data
#				get_filename_component(name "${object}" NAME_WLE)
#				set(output "${CMAKE_CURRENT_BINARY_DIR}/${name}_rc.py")

#				execute_process(
#					COMMAND ${PYTHON_ROOT}/PCbuild/amd64/python.exe
#						-I
#						-m PyQt6.pyrcc_main
#						-o "${output}"
#						"${object}"
#					WORKING_DIRECTORY ${PYTHON_ROOT})

#				list(APPEND data_files "${output}")
			elseif("${ext}" STREQUAL ".json")
				# copy .json files in data
				list(APPEND data_files "${object}")
			endif()
		endif()
	endforeach()

	# files that go directly in bin/plugins
	install(
		FILES ${src_files}
		DESTINATION ${install_dir})

	# files that go in bin/plugins/data
	install(
		FILES ${data_files}
		DESTINATION ${install_dir}/data)

	# directories that go in bin/plugins/data
	install(
		DIRECTORY ${data_dirs}
		DESTINATION ${install_dir}/data
		FILES_MATCHING PATTERN "*.py")
endmacro()
