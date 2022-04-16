cmake_minimum_required(VERSION 3.16)

include(CMakeParseArguments)

function (mo2_set_if_not_defined NAME VALUE)
	if (NOT DEFINED ${NAME})
		set(${NAME} ${VALUE} PARENT_SCOPE)
	endif()
endfunction()

function(mo2_set_project_to_run_from_install)
	cmake_parse_arguments(MO2 "" "PROJECT;EXECUTABLE" "" ${ARGN})

	set(vcxproj_user_file "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT}.vcxproj.user")

	if(NOT EXISTS ${vcxproj_user_file})
		file(WRITE ${vcxproj_user_file}
			"<?xml version=\"1.0\" encoding=\"utf-8\"?>
				<Project ToolsVersion=\"Current\" xmlns=\"http://schemas.microsoft.com/developer/msbuild/2003\">
				  <PropertyGroup>
					<LocalDebuggerWorkingDirectory>${CMAKE_INSTALL_PREFIX}/bin</LocalDebuggerWorkingDirectory>
					<DebuggerFlavor>WindowsLocalDebugger</DebuggerFlavor>
					<LocalDebuggerCommand>${CMAKE_INSTALL_PREFIX}/bin/${EXECUTABLE}</LocalDebuggerCommand>
				  </PropertyGroup>
				</Project>")
	endif()
endfunction()

macro(mo2_required_variable)
	cmake_parse_arguments(REQ_VAR "" "NAME;TYPE;DESC" "" ${ARGN})

	if(NOT DEFINED REQ_VAR_DESC)
		set(REQ_VAR_DESC "${name}")
	endif()

	if(NOT DEFINED ${REQ_VAR_NAME})
		message(FATAL_ERROR "${REQ_VAR_NAME} is not defined")
	endif()

	set(${REQ_VAR_NAME} ${${REQ_VAR_NAME}} CACHE ${REQ_VAR_TYPE} "${REQ_VAR_DESC}")
endmacro()

function(mo2_glob_files VARNAME)
endfunction()

function(mo2_add_filter)
	cmake_parse_arguments(PARSE_ARGV 0 add_filter "" "NAME" "FILES;GROUPS")

	set(files ${add_filter_FILES})

	foreach(f ${add_filter_GROUPS})
		set(files ${files} ${f}.cpp ${f}.h ${f}.inc)
	endforeach()

	string(REPLACE "/" "\\" filter_name ${add_filter_NAME})
	source_group(${filter_name} FILES ${files})
endfunction()

function(mo2_configure_target MO2_TARGET)
	cmake_parse_arguments(MO2 "" "WARNINGS;PERMISSIVE;BIGOBJ;CLI;TRANSLATIONS;EXTRA_TRANSLATIONS" "" ${ARGN})

	# configure parameters and compiler flags
	mo2_set_if_not_defined(MO2_WARNINGS ON)
	mo2_set_if_not_defined(MO2_PERMISSIVE OFF)
	mo2_set_if_not_defined(MO2_BIGOBJ OFF)
	mo2_set_if_not_defined(MO2_CLI OFF)
	mo2_set_if_not_defined(MO2_TRANSLATIONS ON)
	mo2_set_if_not_defined(MO2_EXTRA_TRANSLATIONS "")

	set(COMPILE_FLAGS "/std:c++latest /MP")
	set(OPTIMIZE_COMPILE_FLAGS "/O2")
	set(OPTIMIZE_LINK_FLAGS "/LTCG /INCREMENTAL:NO /OPT:REF /OPT:ICF")

	if(${MO2_WARNINGS})
		set(COMPILE_FLAGS "${COMPILE_FLAGS} /Wall /wd4464")
	endif()

	if(NOT ${MO2_PERMISSIVE})
		set(COMPILE_FLAGS "${COMPILE_FLAGS} /permissive-")
	endif()

	if(${MO2_BIGOBJ})
		set(COMPILE_FLAGS "${COMPILE_FLAGS} /bigobj")
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

	source_group(src REGULAR_EXPRESSION ".*\\.(h|cpp)")
	source_group(ui REGULAR_EXPRESSION ".*\\.ui")
	source_group(cmake FILES CMakeLists.txt)
	source_group(autogen FILES ${rule_files} ${qm_files} ${ui_header_files})
	source_group(autogen REGULAR_EXPRESSION ".*\\cmake_pch.*")
	source_group(resources FILES ${rc_files} ${qrc_files})

	if(${MO2_TRANSLATIONS})
		qt5_create_translation(
			qm_files
			${source_files} ${header_files} ${ui_files} ${MO2_EXTRA_TRANSLATIONS}
			${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}_en.ts
			OPTIONS -silent
		)
	endif()

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
            set_target_properties(${MO2_TARGET} PROPERTIES
                COMMON_LANGUAGE_RUNTIME "")
        else()
            set(COMPILE_FLAGS "${COMPILE_FLAGS} /clr")
            string(REPLACE "/EHs" "/EHa" CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS})
        endif()
    endif()

	set_target_properties(${MO2_TARGET} PROPERTIES
		COMPILE_FLAGS "${COMPILE_FLAGS}"
		VS_STARTUP_PROJECT ${PROJECT_NAME})

	set_target_properties(${MO2_TARGET} PROPERTIES
		COMPILE_FLAGS_RELWITHDEBINFO "${OPTIMIZE_COMPILE_FLAGS}")

	set_target_properties(${MO2_TARGET} PROPERTIES
		LINK_FLAGS_RELWITHDEBINFO "${OPTIMIZE_LINK_FLAGS}")

	mo2_set_project_to_run_from_install(
		PROJECT ${PROJECT_NAME} EXECUTABLE ModOrganizer.exe)

endfunction()

function(mo2_configure_tests MO2_TARGET)
	mo2_configure_target(${MO2_TARGET} ${ARGN})

	find_package(GTest REQUIRED)
	set_property(TARGET ${MO2_TARGET} PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded")
	target_link_libraries(${MO2_TARGET}
		PRIVATE mo2::uibase GTest::gtest GTest::gmock GTest::gtest_main)

	gtest_discover_tests(${MO2_TARGET} WORKING_DIRECTORY ${MO2_INSTALL_PATH}/bin)
endfunction()

function(mo2_install_target MO2_TARGET)

	install(TARGETS ${MO2_TARGET} RUNTIME DESTINATION bin)
	install(TARGETS ${MO2_TARGET} ARCHIVE DESTINATION libs)
	install(FILES $<TARGET_PDB_FILE:${MO2_TARGET}> DESTINATION pdb)
endfunction()
