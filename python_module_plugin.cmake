cmake_minimum_required(VERSION 3.16)
include(${CMAKE_CURRENT_LIST_DIR}/python.cmake)

if(NOT DEFINED install_dir)
	set(install_dir bin/plugins)
endif()


macro(do_project)
	do_python_project()
endmacro()

macro(do_src)
	# this copies all the .py files into ${install_dir}/${PROJECT_NAME}

	# resources in the src directory
	file(GLOB_RECURSE resources ${CMAKE_SOURCE_DIR}/*.ui ${CMAKE_SOURCE_DIR}/*.qrc)

	foreach(object ${resources})
		get_filename_component(ext "${object}" LAST_EXT)

		if("${ext}" STREQUAL ".ui")
			# process .ui files and copy the resulting .py in data
			get_filename_component(name "${object}" NAME_WLE)
			get_filename_component(folder "${object}" DIRECTORY)
			set(output "${folder}/${name}.py")

			execute_process(
				COMMAND ${PYTHON_ROOT}/PCbuild/amd64/python.exe
					-I
					-m PyQt5.uic.pyuic
					-o "${output}"
					"${object}"
				WORKING_DIRECTORY ${PYTHON_ROOT})

			list(APPEND src_files "${output}")
		elseif("${ext}" STREQUAL ".qrc")
			# process .qrc files and copy the resulting .py in data
			get_filename_component(name "${object}" NAME_WLE)
			get_filename_component(folder "${object}" DIRECTORY)
			set(output "${folder}/${name}.py")

			execute_process(
				COMMAND ${PYTHON_ROOT}/PCbuild/amd64/python.exe
					-I
					-m PyQt5.pyrcc_main
					-o "${output}"
					"${object}"
				WORKING_DIRECTORY ${PYTHON_ROOT})

			list(APPEND src_files "${output}")
		endif()
	endforeach()

	file(GLOB_RECURSE src_files RELATIVE ${CMAKE_SOURCE_DIR} ${CMAKE_SOURCE_DIR}/*.py)

	# # directories that go in bin/plugins/${name}
	install(
		DIRECTORY ${CMAKE_SOURCE_DIR}
		DESTINATION ${install_dir}
		FILES_MATCHING PATTERN "*.py"
		PATTERN ".git*" EXCLUDE
		PATTERN "vsbuild" EXCLUDE)
endmacro()
