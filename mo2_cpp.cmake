cmake_minimum_required(VERSION 3.16)

include(CMakeParseArguments)
include(${CMAKE_CURRENT_LIST_DIR}/mo2_utils.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/mo2_targets.cmake)

#! mo2_configure_target : do basic configuration for a MO2 target
#
# this functions does many things:
# - glob relevant files and add them to the target
# - set many compile flags, definitions, etc.
# - add step to create translations (if not turned OFF)
#
# \param:WARNINGS enable all warnings (default ON)
# \param:PERMISSIVE permissive mode (default OFF)
# \param:BIGOBJ enable bigobj (default OFF)
# \param:CLI enable C++/CLR (default OFF)
# \param:TRANSLATIONS generate translations (default ON)
# \param:AUTOMOC automoc (and autouic, autoqrc), (default ON)
# \param:BOOST add boost includes or library (OFF, INC, LIB), (default OFF)
# \param:EXTRA_TRANSLATIONS extra translations to include
#
function(mo2_configure_target MO2_TARGET)
	cmake_parse_arguments(MO2 ""
		"WARNINGS;PERMISSIVE;BIGOBJ;CLI;TRANSLATIONS;AUTOMOC"
		"EXTRA_TRANSLATIONS;PUBLIC_DEPENDS;PRIVATE_DEPENDS"
		${ARGN})

	# configure parameters and compiler flags
	mo2_set_if_not_defined(MO2_WARNINGS ON)
	mo2_set_if_not_defined(MO2_PERMISSIVE OFF)
	mo2_set_if_not_defined(MO2_BIGOBJ OFF)
	mo2_set_if_not_defined(MO2_CLI OFF)
	mo2_set_if_not_defined(MO2_TRANSLATIONS ON)
	mo2_set_if_not_defined(MO2_AUTOMOC ON)
	mo2_set_if_not_defined(MO2_EXTRA_TRANSLATIONS "")
	mo2_set_if_not_defined(MO2_PUBLIC_DEPENDS "")
	mo2_set_if_not_defined(MO2_PRIVATE_DEPENDS "")

	if (${MO2_AUTOMOC})
		find_package(Qt5 COMPONENTS Widgets REQUIRED)
		set_target_properties(${MO2_TARGET}
			PROPERTIES AUTOMOC ON AUTOUIC ON AUTORCC ON)
	endif()

	target_compile_options(${MO2_TARGET} PRIVATE "/std:c++latest" "/MP")

	set_target_properties(${MO2_TARGET} PROPERTIES
		COMPILE_FLAGS_RELWITHDEBINFO "/O2")

	# VS emits a warning for LTCG, at least for uibase, so maybe not required?
	set_target_properties(${MO2_TARGET} PROPERTIES
		LINK_FLAGS_RELWITHDEBINFO "/LTCG /INCREMENTAL:NO /OPT:REF /OPT:ICF")

	if(${MO2_WARNINGS})
		target_compile_options(${MO2_TARGET} PRIVATE "/Wall" "/wd4464")
	endif()

	if(NOT ${MO2_PERMISSIVE})
		target_compile_options(${MO2_TARGET} PRIVATE "/permissive-")
	endif()

	if(${MO2_BIGOBJ})
		target_compile_options(${MO2_TARGET} PRIVATE "/bigobj")
	endif()

	# find source files
	if(DEFINED AUTOGEN_BUILD_DIR)
		set(UI_HEADERS_DIR ${AUTOGEN_BUILD_DIR})
	else()
		set(UI_HEADERS_DIR ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_autogen/include_RelWithDebInfo)
	endif()

	file(GLOB_RECURSE source_files CONFIGURE_DEPENDS *.cpp)
	file(GLOB_RECURSE header_files CONFIGURE_DEPENDS *.h)
	file(GLOB_RECURSE qrc_files CONFIGURE_DEPENDS *.qrc)
	file(GLOB_RECURSE rc_files CONFIGURE_DEPENDS *.rc)
	file(GLOB_RECURSE ui_files CONFIGURE_DEPENDS *.ui)
	file(GLOB_RECURSE ui_header_files CONFIGURE_DEPENDS ${UI_HEADERS_DIR}/*.h)
	file(GLOB_RECURSE rule_files CONFIGURE_DEPENDS ${CMAKE_BINARY_DIR}/*.rule)
	file(GLOB_RECURSE misc_files CONFIGURE_DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/../*.natvis)

	source_group(src REGULAR_EXPRESSION ".*\\.(h|cpp)")
	source_group(ui REGULAR_EXPRESSION ".*\\.ui")
	source_group(cmake FILES CMakeLists.txt)
	source_group(autogen FILES ${rule_files} ${qm_files} ${ui_header_files})
	source_group(autogen REGULAR_EXPRESSION ".*\\cmake_pch.*")
	source_group(resources FILES ${rc_files} ${qrc_files})

	if(${MO2_TRANSLATIONS})
		find_package(Qt5LinguistTools)
		qt5_create_translation(
			qm_files
			${source_files} ${header_files} ${ui_files} ${MO2_EXTRA_TRANSLATIONS}
			${CMAKE_CURRENT_SOURCE_DIR}/${MO2_TARGET}_en.ts
			OPTIONS -silent
		)
	endif()

	target_sources(${MO2_TARGET}
		PRIVATE
		${source_files}
		${header_files}
		${ui_files}
		${ui_header_files}
		${qrc_files}
		${rc_files}
		${misc_files}
		${qm_files})

	execute_process(
	  COMMAND git log -1 --format=%h
	  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
	  OUTPUT_VARIABLE GIT_COMMIT_HASH
	  OUTPUT_STRIP_TRAILING_WHITESPACE
	)

	target_compile_definitions(
		${MO2_TARGET}
		PRIVATE
		_UNICODE
		UNICODE
		NOMINMAX
		_CRT_SECURE_NO_WARNINGS
		BOOST_CONFIG_SUPPRESS_OUTDATED_MESSAGE
		_SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING
		QT_MESSAGELOGCONTEXT
		GITID="${GIT_COMMIT_HASH}")

	if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/pch.h)
		target_precompile_headers(${PROJECT_NAME}
			PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/pch.h)
	endif()

    if(${MO2_CLI})
        if (CMAKE_GENERATOR MATCHES "Visual Studio")
            set_target_properties(${MO2_TARGET} PROPERTIES COMMON_LANGUAGE_RUNTIME "")
        else()
			# can this really happen?
            set(COMPILE_FLAGS "${COMPILE_FLAGS} /clr")
            string(REPLACE "/EHs" "/EHa" CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})
        endif()
    endif()

	set_target_properties(${MO2_TARGET} PROPERTIES VS_STARTUP_PROJECT ${MO2_TARGET})

	target_link_libraries(${MO2_TARGET} PRIVATE Version Dbghelp)

	if (MO2_PUBLIC_DEPENDS)
		mo2_add_dependencies(${MO2_TARGET} PUBLIC ${MO2_PUBLIC_DEPENDS})
	endif()

	if (MO2_PRIVATE_DEPENDS)
		mo2_add_dependencies(${MO2_TARGET} PRIVATE ${MO2_PRIVATE_DEPENDS})
	endif()

endfunction()

#! mo2_configure_tests : configure a target as a MO2 C++ tests
#
# extra arguments are given to mo2_configure_target
#
function(mo2_configure_tests MO2_TARGET)
	mo2_find_uibase()

	mo2_configure_target(${MO2_TARGET} TRANSLATIONS OFF AUTOMOC OFF ${ARGN})
	set_target_properties(${MO2_TARGET} PROPERTIES MO2_TARGET_TYPE "tests")

	find_package(GTest REQUIRED)
	set_property(TARGET ${MO2_TARGET} PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded")
	target_link_libraries(${MO2_TARGET}
		PRIVATE mo2::uibase GTest::gtest GTest::gmock GTest::gtest_main)

	# this would be nice but it requires Qt DLL in the path, etc., which is kind of
	# a PITA, and not working right now
	# gtest_discover_tests(${MO2_TARGET} WORKING_DIRECTORY ${MO2_INSTALL_PATH}/bin)
endfunction()

#! mo2_configure_uibase : configure the uibase target for MO2
#
# this function does mostly nothing except calling mo2_configure_target, but is useful
# to be consistent with other mo2_configure_XXX
#
function(mo2_configure_uibase MO2_TARGET)
	if (NOT (${MO2_TARGET} STREQUAL "uibase"))
		message(WARNING "mo2_configure_uibase() should only be used on the uibase target")
	endif()

	mo2_configure_target(${MO2_TARGET} ${ARGN})
	set_target_properties(${MO2_TARGET} PROPERTIES MO2_TARGET_TYPE "uibase")

	target_include_directories(${MO2_TARGET} PUBLIC
		${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/game_features)
endfunction()

#! mo2_configure_plugin : configure a target as a MO2 C++ plugin
#
# extra arguments are given to mo2_configure_target
#
function(mo2_configure_plugin MO2_TARGET)
	mo2_configure_target(${MO2_TARGET} ${ARGN})
	mo2_add_dependencies(${MO2_TARGET} PRIVATE uibase)

	set_target_properties(${MO2_TARGET} PROPERTIES MO2_TARGET_TYPE "plugin")
endfunction()

#! mo2_configure_library : configure a C++ library (NOT a plugin)
#
# extra arguments are given to mo2_configure_target
#
function(mo2_configure_library MO2_TARGET)
	mo2_configure_target(${MO2_TARGET} AUTOMOC OFF TRANSLATIONS OFF ${ARGN})

	get_target_property(TARGET_TYPE ${MO2_TARGET} TYPE)

	target_include_directories(${MO2_TARGET}
		PUBLIC ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR})

	if (${TARGET_TYPE} STREQUAL "STATIC_LIBRARY")
		set_target_properties(${MO2_TARGET} PROPERTIES MO2_TARGET_TYPE "library-static")
	else()
		set_target_properties(${MO2_TARGET} PROPERTIES MO2_TARGET_TYPE "library-shared")
	endif()
endfunction()

#! mo2_configure_executable : configure a target as MO2 C++ executable
#
# extra arguments are given to mo2_configure_target
#
function(mo2_configure_executable MO2_TARGET)
	cmake_parse_arguments(MO2 "ELEVATED" "" "" ${ARGN})

	mo2_configure_target(${MO2_TARGET} ${ARGN})
	set_target_properties(${MO2_TARGET}
		PROPERTIES
		WIN32_EXECUTABLE TRUE
		MO2_TARGET_TYPE "executable")

	if (${MO2_ELEVATED})
		# does not work with target_link_options, so keeping it that way for now... this
		# is not a very used option anyway
		set_target_properties(${MO2_TARGET} PROPERTIES LINK_FLAGS
			"/MANIFESTUAC:\"level='requireAdministrator' uiAccess='false'\"")
	endif()
endfunction()

#! mo2_install_target : set install for a MO2 target
#
# for this to work properly, the target must have been configured
#
function(mo2_install_target MO2_TARGET)
	cmake_parse_arguments(MO2 "" "INSTALLDIR" "" ${ARGN})


	get_target_property(MO2_TARGET_TYPE ${MO2_TARGET} MO2_TARGET_TYPE)

	# core install: .lib, .dll or .exe, to the right folder
	if (${MO2_TARGET_TYPE} STREQUAL "uibase")
		install(TARGETS ${MO2_TARGET} RUNTIME DESTINATION bin)
		install(TARGETS ${MO2_TARGET} ARCHIVE DESTINATION libs)
	elseif (${MO2_TARGET_TYPE} STREQUAL "plugin")
		install(TARGETS ${MO2_TARGET} RUNTIME DESTINATION bin/plugins)
		install(TARGETS ${MO2_TARGET} ARCHIVE DESTINATION libs)
	elseif (${MO2_TARGET_TYPE} STREQUAL "library-static")
		install(TARGETS ${MO2_TARGET} ARCHIVE DESTINATION libs)
	elseif (${MO2_TARGET_TYPE} STREQUAL "library-shared")
		mo2_set_if_not_defined(MO2_INSTALLDIR "bin/dlls")
		install(TARGETS ${MO2_TARGET} RUNTIME DESTINATION ${MO2_INSTALLDIR})
		install(TARGETS ${MO2_TARGET} ARCHIVE DESTINATION libs)
	elseif (${MO2_TARGET_TYPE} STREQUAL "executable")
		mo2_set_if_not_defined(MO2_INSTALLDIR "bin")
		install(TARGETS ${MO2_TARGET} RUNTIME DESTINATION ${MO2_INSTALLDIR})
	else()
		message(ERROR "unknown MO2 target type for target '${MO2_TARGET}', did you forget using mo2_configure_XXX?")
	endif()

	# install PDB if possible
	if (NOT (${MO2_TARGET_TYPE} STREQUAL "library-static"))
		install(FILES $<TARGET_PDB_FILE:${MO2_TARGET}> DESTINATION pdb)
	endif()

	# set project to run from main MO2 executable or from themselves for executable
	if (${MO2_TARGET_TYPE} STREQUAL "executable")
		get_target_property(output_name ${MO2_TARGET} OUTPUT_NAME)
		if("${output_name}" STREQUAL "output_name-NOTFOUND")
			set(output_name ${MO2_TARGET})

			mo2_set_project_to_run_from_install(
				PROJECT ${PROJECT_NAME} EXECUTABLE ${CMAKE_INSTALL_PREFIX}/bin/${output_name})
		endif()
	elseif(NOT (${MO2_TARGET_TYPE} STREQUAL "library-static"))
		mo2_set_project_to_run_from_install(
			PROJECT ${PROJECT_NAME} EXECUTABLE ${CMAKE_INSTALL_PREFIX}/bin/ModOrganizer.exe)
	endif()

endfunction()
