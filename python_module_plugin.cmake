cmake_minimum_required(VERSION 3.16)
include(${CMAKE_CURRENT_LIST_DIR}/python.cmake)

if(NOT DEFINED install_dir)
	set(install_dir "bin/plugins/${CMAKE_PROJECT_NAME}")
endif()

if(NOT DEFINED res_dir)
	set(res_dir res)
endif()

if(NOT DEFINED lib_dir)
	set(lib_dir lib)
endif()

macro(do_project)
	do_python_project()

	# install requirements if there are any
	if(EXISTS "${CMAKE_SOURCE_DIR}/plugin-requirements.txt")
		add_custom_target(libs ALL
			COMMAND ${PYTHON_ROOT}/PCbuild/amd64/python.exe
					-I
					-m pip
					install --force --disable-pip-version-check
					--target="${CMAKE_SOURCE_DIR}/${lib_dir}"
					-r "${CMAKE_SOURCE_DIR}/plugin-requirements.txt"
			WORKING_DIRECTORY ${PYTHON_ROOT}
			DEPENDS "${CMAKE_SOURCE_DIR}/plugin-requirements.txt")
	endif()
endmacro()

macro(do_src)
	# this copies all the .py files into ${install_dir}/${PROJECT_NAME}

	if(EXISTS "${CMAKE_SOURCE_DIR}/__init__.py")
		set(src_dir ${CMAKE_SOURCE_DIR})
	else()
		set(src_dir ${CMAKE_SOURCE_DIR}/src)
	endif()

	# resources in the src directory
	file(GLOB_RECURSE resources ${src_dir}/*.ui ${src_dir}/*.qrc)

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
					-m PyQt6.uic.pyuic
					-o "${output}"
					"${object}"
				WORKING_DIRECTORY ${PYTHON_ROOT})

			list(APPEND src_files "${output}")
#		elseif("${ext}" STREQUAL ".qrc")
#			# process .qrc files and copy the resulting .py in data
#			get_filename_component(name "${object}" NAME_WLE)
#			get_filename_component(folder "${object}" DIRECTORY)
#			set(output "${folder}/${name}.py")

#			execute_process(
#				COMMAND ${PYTHON_ROOT}/PCbuild/amd64/python.exe
#					-I
#					-m PyQt6.pyrcc_main
#					-o "${output}"
#					"${object}"
#				WORKING_DIRECTORY ${PYTHON_ROOT})

			list(APPEND src_files "${output}")
		endif()
	endforeach()

	file(GLOB_RECURSE src_files RELATIVE ${src_dir} ${src_dir}/*.py)
	
	add_custom_target(${PROJECT_NAME})
	target_sources(${PROJECT_NAME} PRIVATE ${src_dir}/${src_files})

	# directories that go in bin/plugins/${name}
	install(
		DIRECTORY "${src_dir}/"
		DESTINATION ${install_dir}
		FILES_MATCHING PATTERN "*.py"
		PATTERN ".git*" EXCLUDE
		PATTERN "vsbuild" EXCLUDE)

	# copy the resource directory if it exists
	if(EXISTS "${CMAKE_SOURCE_DIR}/${res_dir}")
		install(
			DIRECTORY "${CMAKE_SOURCE_DIR}/${res_dir}"
			DESTINATION ${install_dir}
		)
	endif()

	if(EXISTS "${CMAKE_SOURCE_DIR}/plugin-requirements.txt")
		install(
			DIRECTORY "${CMAKE_SOURCE_DIR}/${lib_dir}"
			DESTINATION ${install_dir}
		)
	endif()

endmacro()
