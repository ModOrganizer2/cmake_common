cmake_minimum_required(VERSION 3.16)

include(${CMAKE_CURRENT_LIST_DIR}/helpers/PyQt5TranslationMacros.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/mo2_utils.cmake)

#! mo2_python_translations : create translations for a python target
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

function(mo2_configure_python_module MO2_TARGET)
    cmake_parse_arguments(MO2 "" "LIBDIR;RESDIR" "" ${ARGN})

    mo2_set_if_not_defined(MO2_LIBDIR "lib")
    mo2_set_if_not_defined(MO2_RESDIR "res")

    set(res_dir "${PROJECT_SOURCE_DIR}/${MO2_RESDIR}")
    set(lib_dir "${PROJECT_SOURCE_DIR}/${MO2_LIBDIR}")

    # install requirements if there are any
    if(EXISTS "${PROJECT_SOURCE_DIR}/plugin-requirements.txt")
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
    endif()

	# resources in the src directory
	file(GLOB_RECURSE resources
        ${CMAKE_CURRENT_SOURCE_DIR}/*.ui ${CMAKE_CURRENT_SOURCE_DIR}/*.qrc)

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

	file(GLOB_RECURSE src_files
        RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/*.py)

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


#! mo2_configure_python : configure a MO2 python target
#
# \param:MODULE indicates if this is a Python module plugin or a file plugin
#
function(mo2_configure_python MO2_TARGET)
    cmake_parse_arguments(MO2 "MODULE" "TRANSLATIONS;LIB;RES" "" ${ARGN})

	mo2_set_if_not_defined(MO2_TRANSLATIONS ON)

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
        mo2_configure_python_file(${MO2_TARGET} ${ARGN})
    endif()

endfunction()
