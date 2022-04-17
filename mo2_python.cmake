cmake_minimum_required(VERSION 3.16)

include(${CMAKE_CURRENT_LIST_DIR}/helpers/PyQt5TranslationMacros.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/mo2_utils.cmake)

#! mo2_python_translations : create translations for a python target
#
function(mo2_python_translations MO2_TARGET)
    find_package(Qt5LinguistTools)

    file(GLOB_RECURSE objects LIST_DIRECTORIES true ${CMAKE_CURRENT_SOURCE_DIR}/*)

    set(dirs "")
    foreach(o ${objects})
        if(IS_DIRECTORY ${o})
            list(APPEND dirs ${o})
        endif()
    endforeach()

    pyqt5_create_translation(
        qm_files
        ${CMAKE_CURRENT_SOURCE_DIR} ${dirs}
        ${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}_en.ts
    )

	add_custom_target("${MO2_TARGET}_translations" DEPENDS ${qm_files})
    add_dependencies(${MO2_TARGET} "${MO2_TARGET}_translations")

endfunction()

#! mo2_python_uifiles : create .py files from .ui files for a python target
#
# \param:INPLACE if specified, .py files are generated next to the .ui files, useful
#     for Python modules, otherwise files are generated in the binary directory
# \param:FILES list of .ui files to generate .py files from
#
function(mo2_python_uifiles MO2_TARGET)
	cmake_parse_arguments(MO2 "INPLACE" "" "FILES" ${ARGN})

	if (NOT MO2_FILES)
		return()
	endif()

	message(DEBUG "generating .py from ui files: ${MO2_FILES}")

	set(pyui_files "")
	foreach (UI_FILE ${MO2_FILES})
		get_filename_component(name "${UI_FILE}" NAME_WLE)
		if (${MO2_INPLACE})
			get_filename_component(folder "${UI_FILE}" DIRECTORY)
		else()
			set(folder "${CMAKE_CURRENT_BINARY_DIR}")
		endif()

		set(output "${folder}/${name}.py")
		add_custom_command(
			OUTPUT "${output}"
			COMMAND ${PYTHON_ROOT}/PCbuild/amd64/python.exe
				-I
				-m PyQt5.uic.pyuic
				-o "${output}"
				"${UI_FILE}"
			WORKING_DIRECTORY ${PYTHON_ROOT}
			DEPENDS "${UI_FILE}"
		)

		list(APPEND pyui_files "${output}")
	endforeach()

	add_custom_target("${MO2_TARGET}_uic" DEPENDS ${pyui_files})
	add_dependencies(${MO2_TARGET} "${MO2_TARGET}_uic")

endfunction()

#! mo2_python_rcfiles : create .py files from .qrc files for a python target
#
# \param:INPLACE if specified, .py files are generated next to the .qrc files, useful
#     for Python modules, otherwise files are generated in the binary directory
# \param:FILES list of .qrc files to generate .py files from
#
function(mo2_python_rcfiles MO2_TARGET)
	cmake_parse_arguments(MO2 "" "INPLACE" "FILES" ${ARGN})

	if (NOT MO2_FILES)
		return()
	endif()

	message(DEBUG "generating .py from qrc files: ${MO2_FILES}")

	set(pyrc_files "")
	foreach (RC_FILE ${MO2_FILES})
		get_filename_component(name "${RC_FILE}" NAME_WLE)
		get_filename_component(folder "${RC_FILE}" DIRECTORY)
		if (${MO2_INPLACE})
			get_filename_component(folder "${RC_FILE}" DIRECTORY)
		else()
			set(folder "${CMAKE_CURRENT_BINARY_DIR}")
		endif()


		set(output "${folder}/${name}_rc.py")
		add_custom_command(
			OUTPUT "${output}"
			COMMAND ${PYTHON_ROOT}/PCbuild/amd64/python.exe
				-I
				-m PyQt5.pyrcc_main
				-o "${output}"
				"${RC_FILE}"
			WORKING_DIRECTORY ${PYTHON_ROOT}
			DEPENDS "${RC_FILE}"
		)

		list(APPEND pyrc_files "${output}")
	endforeach()

	add_custom_target("${MO2_TARGET}_qrc" DEPENDS ${pyrc_files})
	add_dependencies(${MO2_TARGET} "${MO2_TARGET}_qrc")

endfunction()

#! mo2_python_requirements : install requirements for a python target
#
function(mo2_python_requirements MO2_TARGET)
	cmake_parse_arguments(MO2 "" "LIBDIR" "")

	add_custom_command(
		OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/pip.log"
		COMMAND ${PYTHON_ROOT}/PCbuild/amd64/python.exe
				-I
				-m pip
				install --force --upgrade --disable-pip-version-check
				--target="${lib_dir}"
				--log="${CMAKE_CURRENT_BINARY_DIR}/pip.log"
				-r "${PROJECT_SOURCE_DIR}/plugin-requirements.txt"
		WORKING_DIRECTORY ${PYTHON_ROOT}
		DEPENDS "${PROJECT_SOURCE_DIR}/plugin-requirements.txt"
	)
	add_custom_target("${MO2_TARGET}_libs"
		DEPENDS "${CMAKE_CURRENT_BINARY_DIR}/pip.log")
	add_dependencies(${MO2_TARGET} "${MO2_TARGET}_libs")
endfunction()

function(mo2_configure_python_module MO2_TARGET)
    cmake_parse_arguments(MO2 "" "LIBDIR;RESDIR" "" ${ARGN})

    mo2_set_if_not_defined(MO2_LIBDIR "lib")
    mo2_set_if_not_defined(MO2_RESDIR "res")

    set(res_dir "${PROJECT_SOURCE_DIR}/${MO2_RESDIR}")
    set(lib_dir "${PROJECT_SOURCE_DIR}/${MO2_LIBDIR}")

    # install requirements if there are any
    if(EXISTS "${PROJECT_SOURCE_DIR}/plugin-requirements.txt")
		mo2_python_requirements(${MO2_TARGET} LIBDIR "${lib_dir}")
    endif()

	# ui files
	file(GLOB_RECURSE ui_files ${CMAKE_CURRENT_SOURCE_DIR}/*.ui)
	mo2_python_uifiles(${MO2_TARGET} INPLACE FILES ${ui_files})

	# qrc file
	file(GLOB_RECURSE qrc_files ${CMAKE_CURRENT_SOURCE_DIR}/*.qrc)
	mo2_python_rcfiles(${MO2_TARGET} INPLACE FILES ${qrc_files})

    set(install_dir "${MO2_INSTALL_PATH}/bin/plugins/${MO2_TARGET}")

	# directories that go in bin/plugins/${name}
	install(
		DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/"
		DESTINATION ${install_dir}
		FILES_MATCHING PATTERN "*.py"
		PATTERN ".git*" EXCLUDE
		PATTERN "vsbuild" EXCLUDE)

	# copy the resource directory if it exists
	if(EXISTS "${res_dir}")
		install(
			DIRECTORY "${res_dir}"
			DESTINATION ${install_dir}
		)
	endif()

	if(EXISTS "${CMAKE_SOURCE_DIR}/plugin-requirements.txt")
		install(
			DIRECTORY "${lib_dir}"
			DESTINATION ${install_dir}
		)
	endif()

endfunction()

function(mo2_configure_python_simple MO2_TARGET)

	# this copies all the .py files that are directly in src/ into
	# ${install_dir}/
	#
	# any folder that contains at least one .py file (recursive) is copied in
	# bin/plugins/data
	#

	# ui files
	file(GLOB ui_files ${CMAKE_CURRENT_SOURCE_DIR}/*.ui)
	mo2_python_uifiles(${MO2_TARGET} FILES ${ui_files})

	# qrc file
	file(GLOB qrc_files ${CMAKE_CURRENT_SOURCE_DIR}/*.qrc)
	mo2_python_rcfiles(${MO2_TARGET} FILES ${qrc_files})

	# .py files directly in the directory
	file(GLOB py_files ${CMAKE_CURRENT_SOURCE_DIR}/*.py)

	# .json files directly in the directory
	file(GLOB json_files ${CMAKE_CURRENT_SOURCE_DIR}/*.json)

	# subfolder with Python files
	set(data_dirs "")
	file(GLOB everything ${CMAKE_CURRENT_SOURCE_DIR}/*)
	foreach(object ${everything})
		if(IS_DIRECTORY "${object}")
			# only copy interesting directories
			file(GLOB_RECURSE dir_content "${dir}/*.py")
			if (dir_content)
				list(APPEND data_dirs "${object}")
			endif()
		endif()
	endforeach()

    set(install_dir "${MO2_INSTALL_PATH}/bin/plugins")

	# .py files directly in src/ go to plugins/
	install(FILES ${py_files} DESTINATION ${install_dir})

	# folders with Python files go into plugins/data
	install(
		DIRECTORY ${data_dirs}
		DESTINATION "${install_dir}/data"
		FILES_MATCHING PATTERN "*.py")

	# JSON file go in plugins/data
	install(FILES ${json_files} DESTINATION "${install_dir}/data")

	# generated files go in plugins/data
	install(
		DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/"
		DESTINATION "${install_dir}/data"
		FILES_MATCHING
		PATTERN "*.py"
		PATTERN "CMakeFiles" EXCLUDE
		PATTERN "x64" EXCLUDE)

endfunction()

#! mo2_configure_python : configure a MO2 python target
#
# \param:MODULE indicates if this is a Python module plugin or a file plugin
#
function(mo2_configure_python MO2_TARGET)
    cmake_parse_arguments(MO2 "MODULE;SIMPLE" "TRANSLATIONS;LIB;RES" "" ${ARGN})

	mo2_set_if_not_defined(MO2_TRANSLATIONS ON)

	if ((${MO2_MODULE} AND ${MO2_SIMPLE}) OR (NOT(${MO2_MODULE}) AND NOT(${MO2_SIMPLE})))
		message(FATAL_ERROR "mo2_configure_python should be called with either SIMPLE or MODULE")
	endif()

	if(${MO2_TRANSLATIONS})
        mo2_python_translations(${MO2_TARGET})
    endif()

	file(GLOB_RECURSE py_files CONFIGURE_DEPENDS *.py)
	file(GLOB_RECURSE rc_files CONFIGURE_DEPENDS *.rc)
	file(GLOB_RECURSE ui_files CONFIGURE_DEPENDS *.ui)

	target_sources(${MO2_TARGET}
		PRIVATE ${py_files} ${ui_files} ${rc_files} ${qm_files})

    if (${MO2_MODULE})
        mo2_configure_python_module(${MO2_TARGET} ${ARGN})
    else()
        mo2_configure_python_simple(${MO2_TARGET} ${ARGN})
    endif()

endfunction()
